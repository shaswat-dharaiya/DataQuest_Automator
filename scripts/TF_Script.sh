set -e
cd /home/runner/work/Rearc-Quest/Rearc-Quest/pipeline/
terraform init
terraform plan -var
terraform apply -var --auto-approve 
sleep 300
terraform destroy -var --auto-approve
cd  ../bucket
terraform destroy --auto-approve
cd  ../user
terraform destroy -var "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" -var "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" --auto-approve