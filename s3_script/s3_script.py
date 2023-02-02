#!/usr/bin/env python
# coding: utf-8

# # Saving the files to S3 Bucket

# ### Importing the packages

import re
import boto3
import requests
from bs4 import BeautifulSoup

# ### Class constructor

class manage_s3():
    def __init__(self,bucket_name,url,key=None):
        self.bucket_name = bucket_name
        self.url = url

        # AWS credentials as not needed as this script will run on AWS.
        # For running on local machines please uncomment the following lines.
        
        if key:
            with open(key, "r") as f:
                self.AK,self.SK = [x.split()[0] for x in f.readlines()[-1].split(',')]
            self.s3 = boto3.resource('s3',                      
                aws_access_key_id=self.AK, aws_secret_access_key=self.SK
            )
        else:
            self.s3 = boto3.resource('s3')

# ### Get the file names

    def get_name(self):
        soup = BeautifulSoup(requests.get(self.url).text, "html.parser")
        print("Reading file names complete.")
        return [page.string for page in soup.findAll('a', href=re.compile(''))[1:]]


# ### Read the files from S3

    def read_s3(self):
        ret_dict = {}
        # Create bucket if not exist, else get the bucket.
        bucket = self.s3.create_bucket(Bucket=self.bucket_name)
        for i,obj in enumerate(bucket.objects.all()):
            ret_dict[obj.key] = obj.get()['Body'].read()
        print("Reading s3 complete.")
        return ret_dict


# ### Sync the files

    def sync_files(self):
        files = self.get_name()
        s3_files = self.read_s3()
        file_name = s3_files.keys()
        
        print("Uploading/Updating files to s3")
        
        for i, f in enumerate(files):
            file = f'dataset/{f}'
            with requests.get(self.url+f, stream=True) as r:
                if file not in file_name:
                    self.s3.Object(self.bucket_name, file).put(Body=r.content)
                    print(f"{i+1}) {file} uploaded")
                else:
                    if r.content != s3_files[file]:
                        self.s3.Object(self.bucket_name, file).put(Body=r.content)
                        print(f"{i+1}) {file} updated")
                    else:
                        print(f"{i+1}) {file} skipped")
        
        print("Deleting files from s3")
        
        del_f = [f for f in file_name if f.split('/')[-1] not in files]
        for i, f in enumerate(del_f):
            self.s3.Object(self.bucket_name, f).delete()
            print(f"{i+1}) {f} deleted")


# ### Execution

key = "../srd22_accessKeys.csv"
bucket_name = "s1quest"
res_url = "https://download.bls.gov/pub/time.series/pr/"

s = manage_s3(bucket_name, res_url)
s.sync_files()