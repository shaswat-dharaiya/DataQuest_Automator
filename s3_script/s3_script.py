
import sys
import os

sys.path.insert(0,"..")
from classes.ManageS3 import ManageS3


# ### Execution

key = "../srd22_accessKeys.csv" if os.uname()[1] == "Kaushils-MacBook-Pro-2.local" else None
bucket_name = "s1quest"
res_url = "https://download.bls.gov/pub/time.series/pr/"

s = ManageS3(bucket_name, res_url,key)
s.sync_files()