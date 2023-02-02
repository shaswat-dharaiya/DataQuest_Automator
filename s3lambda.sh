# Exit immediately
set -e

# pip install virtualenv
# cd $HOME
# virtualenv -p /usr/bin/* Lambda
# source Lambda/bin/activate
# pwd
# ls ./
# pip install beautifulsoup4
# pip install lxml
# cp /home/runner/work/Rearc-Quest/Rearc-Quest/lambda/s3_script.py ~/Lambda/lib/*/*/
# cd ~/Lambda/lib/*/*/
# zip -r9 lambda_function.zip
echo $VIRTUAL_ENV

# AWS_REGION="us-east-1"
# aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
# ${AWS_ACCESS_KEY_ID}
# ${AWS_SECRET_ACCESS_KEY}
# ${AWS_REGION}
# text
# EOF

# # Use the profile to connect to the s3 bucket
# sh -c "aws s3 cp ./lambda_function.zip s3://${AWS_S3_BUCKET_LAMBDA}/ \
#               --profile rearc-quest-aws \
#               --no-progress $*"

# # Unset the variables.
# aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
# null
# null
# null
# text
# EOF