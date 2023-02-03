
import sys
from os import environ

sys.path.insert(0,"..")
from classes.ManageS3 import ManageS3


# ### Execution

# LH_FLAG is localhost flag which is set on localhost machine but not AWS
key = "../srd22_accessKeys.csv" if environ.get('LH_FLAG') else None
bucket_name = "s1quest"
res_url = "https://download.bls.gov/pub/time.series/pr/"

s = ManageS3(bucket_name, res_url,key)
s.sync_files()

print("Step 1 Execution Complete.")

new_bucket = "s2quest"
api = "https://datausa.io/api/data?drilldowns=Nation&measures=Population"
file_key = "data.json"
s.new_s3_add_files(new_bucket, api,file_key)

print("Step 2 Execution Complete.")