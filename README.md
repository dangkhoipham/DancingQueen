# How to apply CI/CD to AWS Kubernetes
#### This is the demo how to build and apply an web nodejs application to AWS Kubernetes cluster using CodeCommit, CodeBuilt and CodePipeline
## Create AWS EKS using eksctl
### I would like to use eksctl to create AWS EKS for the demo, but you feel free to create it using any tool you'd like, for ex: kops, kubeadm, Terraform, CloudFormation
- 1. Input AWS credentials
```aws configure```
Input Access Key ID, Access Key secret, region and json type
- 2. Create AWS Kubernetest (AWS EKS) using eksctl command
```eksctl create cluster --region=us-east-1 --zones=us-east-1a,us-east-1b --node-type=t3.medium --managed --asg-access --full-ecr-access --appmesh-access  --appmesh-preview-access  --alb-ingress-access```
This command is create AWS EKS cluster on region us-east-1, two AZs us-east-1a and us-east-1b, node type: t3.medium, with Full ECR Access, Mesh service, ALB access. It also creates the Node Group for you. Usually it takes around 10-15 minutes to finish so please be patient. :). If you have any query, please refer to eksctl --help for the detail
- 3. Git clone the respository
```git clone https://github.com/ptchau2003/DancingQueen.git```
This is the simple website (NodeJS) I wrote for charity foundation, we run and donate for the children. I've just learned CSS/HTML/NodeJS for 02-week short course.
```
cloud_user@chauphan1c:~$ git clone https://github.com/ptchau2003/DancingQueen.git
Cloning into 'DancingQueen'...
remote: Enumerating objects: 29, done.
remote: Counting objects: 100% (29/29), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 92 (delta 7), reused 15 (delta 3), pack-reused 63
Unpacking objects: 100% (92/92), done.
```
