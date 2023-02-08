# Updates the S3 bucket and Lambda functions
# when a code change occurs to any of the main python files.

set -e



zip -r9 lambda_files.zip /home/runner/work/Rearc-Quest/Rearc-Quest/{classes/ManageS3.py,lambda/*}

cp ../scripts/s3lambda.sh ./
sh ./s3lambda.sh

AWS_REGION="us-east-1"
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
$AWS_ACCESS_KEY_ID
$AWS_SECRET_ACCESS_KEY
$AWS_REGION
text
EOF

aws lambda update-function-code \
--function-name automate_quest \
--zip-file fileb://../lambda_files/lambda_files.zip
--profile rearc-quest-aws

aws lambda update-function-code \
--function-name S4-3 \
--zip-file fileb://../lambda_files/lambda_files.zip
--profile rearc-quest-aws

aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
null
null
null
text
EOF

cd ../
rm -r ./lambda_files
