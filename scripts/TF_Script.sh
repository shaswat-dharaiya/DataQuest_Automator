# Creates the infrastructure
cd ./TF_code/pipeline/
terraform init > /dev/null
terraform plan > /dev/null
terraform apply --auto-approve 