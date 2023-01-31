#!/bin/sh

set -e

AWS_REGION="us-east-1"
if [ -n "$AWS_S3_ENDPOINT" ]; then
  ENDPOINT_APPEND="--endpoint-url $AWS_S3_ENDPOINT"
fi

aws configure --profile rearc-quest-aws <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF

sh -c "aws s3 sync ${SOURCE_DIR:-.} s3://${AWS_S3_BUCKET}/${DEST_DIR} \
              --profile rearc-quest-aws \
              --no-progress \
              ${ENDPOINT_APPEND} $*"

aws configure --profile s3-sync-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF