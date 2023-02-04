# Exit immediately
set -e

AWS_REGION="us-east-1"
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Use the profile to connect to the s3 bucket
aws s3 cp *.zip s3://s2quest/ --profile rearc-quest-aws --no-progress

# Unset the variables.
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
null
null
null
text
EOF