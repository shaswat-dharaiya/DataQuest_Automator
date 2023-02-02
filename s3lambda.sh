# Exit immediately
set -e



AWS_REGION="us-east-1"
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

echo ${AWS_S3_BUCKET_LAMBDA}
echo ${AWS_ACCESS_KEY_ID}
echo ${AWS_SECRET_ACCESS_KEY}
echo ${AWS_REGION}

# Use the profile to connect to the s3 bucket
sh -c "aws s3 sync /home/runner/work/Rearc-Quest/Rearc-Quest/env/lib/*/*/lambda_function.zip s3://${AWS_S3_BUCKET_LAMBDA}/ \
              --profile rearc-quest-aws \
              --no-progress $*"

# Unset the variables.
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
null
null
null
text
EOF