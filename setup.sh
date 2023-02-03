cd ./TF_code/buckets/
terraform init > /dev/null
terraform plan > /dev/null
terraform apply --auto-approve
echo "Buckets created"
cd ../../

mkdir lambda_files 
cp ./{classes/ManageS3.py,lambda/*} ./lambda_files
cd ./lambda_files/
zip -r9 lambda_files.zip * > /dev/null
cp ../scripts/s3lambda.sh ./
sh ./s3lambda.sh
cd ../
rm -r ./lambda_files

sh ./scripts/TF_Script.sh