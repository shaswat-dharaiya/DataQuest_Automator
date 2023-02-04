# Updates the S3 bucket and Lambda functions
# when a code change occurs to any of the main python files.

set -e

mkdir lambda_files 
cp ./{classes/ManageS3.py,lambda/*} ./lambda_files
cd ./lambda_files/
zip -r9 lambda_files.zip * > /dev/null
cp ../scripts/s3lambda.sh ./
sh ./s3lambda.sh

AWS_REGION="us-east-1"
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

aws lambda update-function-code \
--function-name automate_quest \
--region ${AWS_REGION} \
--zip-file fileb://../lambda_files/lambda_files.zip

aws lambda update-function-code \
--function-name S4-3 \
--region ${AWS_REGION} \
--zip-file fileb://../lambda_files/lambda_files.zip


aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
null
null
null
text
EOF

cd ../
rm -r ./lambda_files
