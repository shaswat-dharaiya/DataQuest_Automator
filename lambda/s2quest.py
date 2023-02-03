#!/usr/bin/env python
# coding: utf-8

# ### Import Libraries
import requests
import json
import pandas as pd
import boto3
import requests


def lambda_handler(event, context):

    # ### Step 3.0 - Data Collection

    # #### Data from API

    api = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"

    # Get the data from API.
    # Use json package to parse it and convert it Dict.
    r = json.loads(requests.get(api).text)['data']

    # Convert the Dict to Pandas DataFrame
    # We use pd.to_numeric to convert numeric text to their respective dtypes.
    # errors = 'ignore' will avoid a column if it contains non-numeric text.
    data = pd.DataFrame.from_dict(r).apply(pd.to_numeric, errors="ignore")
    print(data)


    # #### Data from S3 Bucket

    # key = "./srd22_accessKeys.csv"
    key = None
    bucket, file = "s1quest", "dataset/pr.data.0.Current"

    # Use the key from the csv file to access the bucket.
    if key:
        with open(key, "r") as f:
            ACCESS_KEY,SECRET_KEY = [x.split()[0] for x in f.readlines()[-1].split(',')]
        s3 = boto3.resource('s3',
            aws_access_key_id=ACCESS_KEY,aws_secret_access_key=SECRET_KEY
        )
    else:
        s3 = boto3.resource('s3')

    # Get the data file from s3 bucket.
    # The file contains byte literals, we use decode() to convert it string and strip the spaces.
    table = s3.Object(bucket,file).get()['Body'].read().decode().strip()

    # Each line is a row, thus we split the table by '\n'.
    rows = table.split('\n')

    # 1st row contains the column names.
    columns = [col.strip() for col in rows[0].split('\t')]

    # Each cell in the row is tab seperated so we split it using '\t' and strip the spaces
    # 1st row is columns so we exclude it from the main df.
    # We use pd.to_numeric to convert numeric text to their respective dtypes.
    # errors = 'ignore' will avoid a column if it contains non-numeric text.
    # End of the file is something like this: PRS88003203      	2022	Q03	     128.078	\n
    # So initial stripping not only removed the last \n but all the last cell.
    # We use fillna("") fill that last cell.
    df = pd.DataFrame([[cell.strip() for cell in row.split('\t')] for row in rows],
            columns=columns)[1:].apply(pd.to_numeric, errors="ignore").fillna("")
    print(df)

    # ### Step 3.1 - Mean & Standard Deviation
    # 
    # 1. Year $\in$ `[2013,2018]`
    # 2. describe() gives us the statistics of the dataframe
    # 3. We select population
    # 4. T means transpose
    # 5. Select mean & standard deviation

    data[(data['Year'] >= 2013) & (data['Year'] <= 2018)].describe()[['Population']].T[['mean','std']]


    # ### Step 3.2 - Grouping

    # First group by series then perform a nested group of year
    # Performing sum on values will add all the quaterly values
    df_grp = df.groupby(['series_id','year'])['value'].sum()

    # We then perform groupby again on level=0 meaning 1st index, ie. series_id
    # And take the max value out of all the values available for that id using idxmax()
    # reset_index() converts the 2 indexes back to columns.

    # We can simply use this df_grp.groupby(level=0).max()
    # but it will return series_id along with max value, not the year

    df_final = pd.DataFrame(df_grp.loc[df_grp.groupby(level=0).idxmax()]).reset_index()
    print(df_final)


    # ### Step 3.3 - Filtering

    # We filter out the df such that we only get 'PRS30006032' records for 'Q01' period
    df_filter = df[(df['series_id']=='PRS30006032') & (df['period'] == 'Q01')].reset_index(drop=True)

    # Mention the columns we want to display in the final output.
    cols = ['series_id', 'year', 'period', 'value', 'Population']

    # Perform an inner join using the 2 dataframes and merge them.
    # 'left_on' & 'right_on' specifies the column names from respective dfs.
    df_merge = pd.merge(df_filter,data,how='inner', left_on='year', right_on='Year')[cols]
    print(df_merge)
