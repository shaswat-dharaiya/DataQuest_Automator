set -e
cd /home/runner/work/Rearc-Quest/Rearc-Quest/pipeline/
terraform init
terraform plan
terraform apply --auto-approve 
sleep 300
terraform destroy --auto-approve
cd  ../buckets
terraform destroy --auto-approve
cd  ../user
terraform destroy -var "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -var "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" --auto-approve