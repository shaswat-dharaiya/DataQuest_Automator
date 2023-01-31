#!/bin/sh

# Exit immediately
set -e

AWS_REGION="us-east-1"

# configure aa profile and save the credentials to that profile.
# >> /dev/null redirects standard output (stdout) to /dev/null, which discards it.
# 2>&1 redirects standard error (2) to standard output (1),
# which then discards it as well since standard output has already been redirected.
# & indicates a file descriptor.
# There are usually 3 file descriptors - standard input, output, and error.
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

# Use the profile to connect to the s3 bucket
sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
              --profile rearc-quest-aws \
              --no-progress \
              --endpoint-url $*"

# Unset the variables.
aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
null
null
null
text
EOF