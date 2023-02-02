#!/usr/bin/env python
# coding: utf-8
import sys
import requests
import json
import pandas as pd
import boto3

from ManageS3 import ManageS3

# ### Execution

def lambda_handler(event, context):
    # ### Execution
    bucket_name = "s1quest"
    res_url = "https://download.bls.gov/pub/time.series/pr/"

    s = ManageS3(bucket_name, res_url)
    s.sync_files()

    print("Step 1 Execution Complete.")

    new_bucket = "s2quest"
    api = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"
    file_key = "data.json"
    s.new_s3_add_files(new_bucket, api,file_key)

    print("Step 2 Execution Complete.")
