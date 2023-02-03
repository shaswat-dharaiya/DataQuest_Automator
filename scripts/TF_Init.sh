set -e
cd ./user/
terraform init
terraform plan -var "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -var "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
terraform apply -var "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -var "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" --auto-approve 
ls

cd ../buckets/
terraform init
terraform plan
terraform apply --auto-approve

cd ../