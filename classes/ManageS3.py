#!/usr/bin/env python
# coding: utf-8

# # Saving the files to S3 Bucket

# ### Importing the packages

import re
import boto3
import requests
from bs4 import BeautifulSoup

# ### Class constructor

class ManageS3():
    """
    ManageS3 implements 1st steps of the quest.
    1st 3 methods implement the 1st step,
    whereas last method, ie. new_s3_add_files() implements the 2nd step of the quest.
    """
    def __init__(self,bucket_name,url,key=None):
        """
        The constructor is takes in 3 params:
        1. bucket_name: Name of the bucket used for step 1,
        2. url: URL from where the dataset is supposed to be read.
        3. key=None: If localhost, then path to the aws access key.
        """
        self.bucket_name = bucket_name
        self.url = url

        AK, SK = None, None
        if key:
            with open(key, "r") as f:
                AK,SK = [x.split()[0] for x in f.readlines()[-1].split(',')]
                print("Key Accessed")
        
        self.s3 = boto3.resource('s3',                      
            aws_access_key_id=AK, aws_secret_access_key=SK
        )

# ### Get the file names

    def get_name(self):
        """
        Uses BeautifulSoup of bs4 to names of the files in the dataset.
        returns a list of name of files in the dataset.
        """
        soup = BeautifulSoup(requests.get(self.url).text, "html.parser")
        print("Reading file names complete.")
        return [page.string for page in soup.findAll('a', href=re.compile(''))[1:]]


# ### Read the files from S3

    def read_s3(self):
        """
        Uses `create_bucket()` method which is indempotent,
        meaning it will create the bucket if bucket doesn't exist,
        else will simply return the existing bucket.
        """
        ret_dict = {}
        # Create bucket if not exist, else get the bucket.
        bucket = self.s3.create_bucket(Bucket=self.bucket_name)
        for i,obj in enumerate(bucket.objects.all()):
            ret_dict[obj.key] = obj.get()['Body'].read()
        print("Reading s3 complete.")
        return ret_dict


# ### Sync the files

    def sync_files(self):
        """
        Calls `get_name()` & `read_s3()`
        Syncing:
        1. File not in S3 - upload it from dataset to S3.
        2. File contents in S3 different from dataset - replace the file in S3 with the file from dataset.
        3. File in S3 but not in dataset - delete the file from S3.
        """
        files = self.get_name() + ["index.html"]
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

        url = "https://s1quest.s3.amazonaws.com/"
        urls = "".join([f"<a href=\"{url+f}\">{f}</a><br/>" for f in file_name])

        html_template = f"<html><head><title>{self.bucket_name}</title></head><body>{urls}</body></html>"

        object = self.s3.Object(
        bucket_name=self.bucket_name, 
        key='index.html'
        )

        object.put(Body=html_template)

    
    def new_s3_add_files(self, bucket_name, api, key):
        """
        Takes in 3 params: `bucket_name`, `api`, & `key`:
        1. bucket_name: Name of the S3 bucket
        2. api: URL to the api
        3. key: Name of the file to store in S3.
        Uses `create_bucket()` method as well
        """
        r = requests.get(api).text
#         Create the bucket if not exists.
        _ = self.s3.create_bucket(Bucket=bucket_name) 
        self.s3.Object(bucket_name, key).put(Body=r)
        print(f"Data from given API is written to {bucket_name} bucket.")