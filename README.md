# CloudTeam

# This Project will create solution that receives a message from SQS, stores it in S3, and deploys it as a ScaledJob in EKS

## 1 & 2. Python Script / Docker Image (01_python-app)

### 01.

Install docker & aws-cli on your workstation 

### 02.

Create a User in AWS IAM for your workstation with the following AWS managed policies:

```
AmazonEC2ContainerRegistryFullAccess
AmazonS3FullAccess
AmazonSQSFullAccess
AmazonEC2FullAccess
CloudWatchLogsFullAccess
IAMFullAccess
AWSKeyManagementServicePowerUser
AmazonEKSClusterPolicy (You may need to add more eks permissions - if needed, copy from the custom_policy.json file)
```

or create a Custom Policy with the specific Permissions found in the custom_policy.json file


### 03.

Create Access Key & Secret key for that IAM user and enter them in your workstation with the command:

```
aws configure
```

### 04.

cd into the 01_python-app folder and the run the following commands:

```
aws ecr create-repository --repository-name python-app --image-scanning-configuration scanOnPush=true --region <your_region>
aws ecr get-login-password --region <your_region> | docker login --username AWS --password-stdin  <your_account_id>.dkr.ecr.<your_region>.amazonaws.com
docker build -t <your_account_id>.dkr.ecr.-<your_region>.amazonaws.com/python-app  . 
docker push <your_region>.dkr.ecr.<your_region>.amazonaws.com/python-app:latest
```


## 3. Infrastructure Setup (02_terraform)

### 01.

Install Terraform on your workstation

### 02. (Optional)

Create a s3 bucket for storing the Terraform State File

```
aws s3api create-bucket --bucket <your_bucket_name> --region <your_region> --acl private --create-bucket-configuration LocationConstraint=<your_region>
```

Uncomment the lines in 02_terraform/s3.tf file, and edit the details to suit your created bucket 

```
vim 02_terraform/s3.tf
```

### 03.

cd into the 02_terraform folder and edit the variables.tf file to suit your enviorment (These components  will be created by terraform):

```
vim variables.tf
```


### 04.

Run the following commands to initialize, and apply the terraform files

```
terraform init
terraform apply
```

write yes when terraform asks for confirmation 


### 05.

Copy the Output values at the end of terraform creation process, you will need them in the Cluster configuration.


## 4. Cluster Configuration (03_cluster)

### 01.

cd into the 03_cluster folder and run the install.sh script to install kubectl & EKS

```
./install.sh
```

### 02.

configure kubectl to work with your Amazon EKS cluster with the command

```
eksctl utils write-kubeconfig --cluster=<your_cluster_name>
```

### 03. 

Edit the configmap.yaml file with values you copied from the terraform output:

```
vim configmap.yaml
```

### 04.

Run the command :

```
echo -n "your_region" | base64
```

and place in the secret.yaml file under AWS_REGION

```
vim secret.yaml
```

### 05. (Optional)

To view the EKS In the AWS Console run the command:

```
kubectl edit configmap aws-auth -n kube-system
```

and add the line 

```
mapUsers: "- groups: \n  - system:masters\n  userarn: arn:aws:iam::<your_account_id>:<your_username>\n"
```

### 06. 

Setup ArgoCD:

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 07. (Optional)

To Enable ArgoCD Web UI run the following commands:

```
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Browse to URL localhost:8080

```
Username: admin
Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode
```

### 08.

Setup Karpenter (Make sure to edit karpenter-provisioner.yaml and replace the cluster name with yours (lines with the comment) ):

```
kubectl apply --server-side -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.sh_nodepools.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
kubectl apply --server-side -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
kubectl apply -f karpenter-provisioner.yaml
kubectl apply -f karpenter.yaml 
```

### 09.

Setup Keda:

```
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0.yaml
kubectl apply --server-side -f https://github.com/kedacore/keda/releases/download/v2.14.0/keda-2.14.0-core.yaml
kubectl apply -f keda.yaml
```

### 10.

Setup the ScaledJob (Make sure to edit scaledjob.yaml and replace the docker image & queueURL & awsRegion with yours (lines with the comment) ):

```
kubectl apply -f secret.yaml
kubectl apply -f trigger-authentication.yaml
kubectl apply -f configmap.yaml
kubectl apply -f scaledjob.yaml
```

## Testing

### 01.

Run the following command to trigger the scaledJob by sending a message to SQS:

```
aws sqs send-message --queue-url <your_queue_url> --message-body "I want to be in CloudTeam" 
```

### 02.

Run the following command to view the File in the s3 bucket

```
aws s3 ls s3://<your_bucketname>
```

Should Retun the timestamp with the txt file in the timestamp format


## 03. 

To view the job creation process you can run the following commands on separate terrminals:

```
kubectl logs -f -n karpenter -l app.kubernetes.io/name=karpenter
watch -n 1 -t kubectl get nodes
watch -n 1 -t kubectl get jobs
watch -n 1 -t kubectl get pods
```