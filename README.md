# How to apply CI/CD to AWS Kubernetes
#### This is the demo how to build and apply an web nodejs application to AWS Kubernetes cluster using CodeCommit, CodeBuilt and CodePipeline. We use CodeCommit with dancing-queen repository, use CodeBuild to build NodeJs application and create Docker image, put this image to AWS ECR and ready to use this image apply to AWS EKS.

## Create AWS EKS using eksctl
##### I would like to use eksctl to create AWS EKS for the demo, but you feel free to create it using any tool you'd like, for ex: kops, kubeadm, Terraform, CloudFormation. You need to have bastion host or laptop with docker, kubectl and AWS CLI installed.
1. Input AWS credentials
```aws configure```
##### Input Access Key ID, Access Key secret, region and json type
2. Create AWS Kubernetest (AWS EKS) using eksctl command
```eksctl create cluster --region=us-east-1 --zones=us-east-1a,us-east-1b --node-type=t3.medium --managed --asg-access --full-ecr-access --appmesh-access  --appmesh-preview-access  --alb-ingress-access```
##### This command is create AWS EKS cluster on region us-east-1, two AZs us-east-1a and us-east-1b, node type: t3.medium, with Full ECR Access, Mesh service, ALB access. It also creates the Node Group for you. Usually it takes around 10-15 minutes to finish so please be patient. :). If you have any query, please refer to eksctl --help for the detail
3. Git clone the respository
```git clone https://github.com/ptchau2003/DancingQueen.git```
##### This is the simple website (NodeJS) I wrote for charity foundation, we run and donate for the children. I've just learned CSS/HTML/NodeJS for 02-week short course.
```
cloud_user@chauphan1c:~$ git clone https://github.com/ptchau2003/DancingQueen.git
Cloning into 'DancingQueen'...
remote: Enumerating objects: 29, done.
remote: Counting objects: 100% (29/29), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 92 (delta 7), reused 15 (delta 3), pack-reused 63
Unpacking objects: 100% (92/92), done.
```
```
cloud_user@chauphan1c:~$ tree DancingQueen/
DancingQueen/
├── Dockerfile
├── README.md
├── default
├── index.js
├── k8s
│   ├── deployment.yaml
│   └── service.yaml
├── nginx.conf
├── package-lock.json
├── package.json
├── public
│   ├── css
│   │   ├── bootstrap.min.css
│   │   ├── lightbox.css
│   │   ├── owl.carousel.min.css
│   │   ├── owl.theme.default.min.css
│   │   └── styles.css
│   ├── images
│   │   ├── banner1.jpg
│   │   ├── banner2.jpg
│   │   ├── banner3.jpg
│   │   ├── close.png
│   │   ├── g12.jpg
│   │   ├── loading.gif
│   │   ├── logo.png
│   │   ├── next.png
│   │   ├── prev.png
│   │   ├── run1.jpg
│   │   ├── run10.jpg
│   │   ├── run11.jpg
│   │   ├── run12.jpg
│   │   ├── run13.jpg
│   │   ├── run14.jpg
│   │   ├── run15.jpg
│   │   ├── run16.jpg
│   │   ├── run17.jpg
│   │   ├── run18.jpg
│   │   ├── run19.jpg
│   │   ├── run2.jpg
│   │   ├── run20.jpg
│   │   ├── run21.jpg
│   │   ├── run22.jpg
│   │   ├── run23.jpg
│   │   ├── run24.jpg
│   │   ├── run25.jpg
│   │   ├── run26.jpg
│   │   ├── run3.jpg
│   │   ├── run5.jpg
│   │   ├── run6.jpg
│   │   ├── run7.jpg
│   │   ├── run8.jpg
│   │   ├── run9.jpg
│   │   └── walk.jpg
│   └── js
│       ├── bootstrap.min.js
│       ├── jquery-3.5.1.min.js
│       ├── jquery.countup.js
│       ├── lightbox.min.js
│       ├── lightbox.min.map
│       └── owl.carousel.min.js
└── views
    └── pages
        └── index.ejs
```
4.	Check if the node:6 images is available, if not, pull it from Docker Hub by command `docker pull node:6`
##### You should run the node js on AWS ECR, because each time you build, you don't waste time and bandwidth to download it from Docker Hub again, and it will lead to alarm *limit resource* from Docker. Current node maybe  node:11, you may use the latest one, but I use node:6 to demo the upgrade from node:6 to node:11
```
cloud_user@chauphan1c:~/DancingQueen$ docker images
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
dancingqueen                               1.0                 9629e11b10fb        12 hours ago        1.18GB
web-client                                 latest              e80e8f398cbe        6 days ago          1.02GB
photo-storage                              latest              a55255cff09d        6 days ago          1GB
photo-filter                               latest              9e79ede6d0ef        6 days ago          15.7MB
nginx                                      latest              ae2feff98a0c        3 weeks ago         133MB
quay.io/jetstack/cert-manager-controller   v1.1.0              89ac08abb500        6 weeks ago         64.5MB
ubuntu                                     latest              d70eaf7277ea        2 months ago        72.9MB
mven_api                                   latest              0299806524c3        4 months ago        636MB
redis                                      latest              41de2cc0b30e        4 months ago        104MB
postgres                                   latest              62473370e7ee        4 months ago        314MB
golang                                     1.11                43a154fee764        17 months ago       796MB
node                                       6                   ab290b853066        20 months ago       884MB
maven                                      3.6.0-jdk-8         938cf03ad8e9        21 months ago       636MB
```
5. Create ECR repository `node` and `dancing-queen`. Note the repositoryUri returned.
```
cloud_user@chauphan1c:~/DancingQueen$ aws ecr create-repository --repository-name node
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:870472129713:repository/node",
        "registryId": "870472129713",
        "repositoryName": "node",
        "repositoryUri": "870472129713.dkr.ecr.us-east-1.amazonaws.com/node",
        "createdAt": "2021-01-11T07:56:07+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        }
    }
}
```
```
cloud_user@chauphan1c:~/DancingQueen$ aws ecr create-repository --repository-name dancing-queen
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:870472129713:repository/dancing-queen",
        "registryId": "870472129713",
        "repositoryName": "dancing-queen",
        "repositoryUri": "870472129713.dkr.ecr.us-east-1.amazonaws.com/dancing-queen",
        "createdAt": "2021-01-11T07:56:19+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        }
    }
}
```
6.	Docker login to Repository URI as above

```
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 870472129713.dkr.ecr.us-east-1.amazonaws.com
WARNING! Your password will be stored unencrypted in /home/cloud_user/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store
Login Succeeded
```

##### Note: Your credential will be stored on config.json file. It's better use credential store as above suggestion.

7.	Docker tag your local `node` repository

```
docker tag node:6 870472129713.dkr.ecr.us-east-1.amazonaws.com/node:latest
```
```
cloud_user@chauphan1c:~/DancingQueen$ docker images
REPOSITORY                                          TAG                 IMAGE ID            CREATED             SIZE
dancingqueen                                        1.0                 9629e11b10fb        12 hours ago        1.18GB
web-client                                          latest              e80e8f398cbe        6 days ago          1.02GB
photo-storage                                       latest              a55255cff09d        6 days ago          1GB
photo-filter                                        latest              9e79ede6d0ef        6 days ago          15.7MB
nginx                                               latest              ae2feff98a0c        3 weeks ago         133MB
quay.io/jetstack/cert-manager-controller            v1.1.0              89ac08abb500        6 weeks ago         64.5MB
ubuntu                                              latest              d70eaf7277ea        2 months ago        72.9MB
mven_api                                            latest              0299806524c3        4 months ago        636MB
redis                                               latest              41de2cc0b30e        4 months ago        104MB
postgres                                            latest              62473370e7ee        4 months ago        314MB
golang                                              1.11                43a154fee764        17 months ago       796MB
node                                                6                   ab290b853066        20 months ago       884MB
870472129713.dkr.ecr.us-east-1.amazonaws.com/node   latest              ab290b853066        20 months ago       884MB
maven                                               3.6.0-jdk-8         938cf03ad8e9        21 months ago       636MB
```
8.	Put the docker node image to AWS ECR repository node. It’s better to use the AWS ECR repository instead of access to Docker Hub node:6 every build (to reduce cost)

```
docker push 870472129713.dkr.ecr.us-east-1.amazonaws.com/node:latest
```
```
cloud_user@chauphan1c:~/DancingQueen$ docker push 870472129713.dkr.ecr.us-east-1.amazonaws.com/node:latest
The push refers to repository [870472129713.dkr.ecr.us-east-1.amazonaws.com/node]
f39151891503: Pushing [========================================>          ]  4.079MB/5.075MB
f1965d3c206f: Pushing [====>                                              ]   3.65MB/43.3MB
a27518e43e49: Pushing [==================================================>]  349.2kB
910d7fd9e23e: Pushing [>                                                  ]  1.104MB/562.2MB
4230ff7f2288: Pushing [>                                                  ]  1.598MB/141.8MB
2c719774c1e1: Waiting
ec62f19bb3aa: Waiting
f94641f1fe1f: Waiting
```
9.	Modify the Dockerfile to get AWS ECR node repository instead of Docker Hub repository. Change the line using Docker Hub node:6
```
FROM node:6

-->	FROM 870472129713.dkr.ecr.us-east-1.amazonaws.com/node:latest
```
##### Your final file is as below

```
FROM 870472129713.dkr.ecr.us-east-1.amazonaws.com/node:latest

# Deps
RUN apt-get update && apt-get install -y ca-certificates git-core ssh nginx

# Our source
WORKDIR /var/www/html/
ADD . /var/www/html
ADD default /etc/nginx/sites-available

# Start nginx
RUN service nginx start
# Install node deps for each app
RUN npm install --quiet
CMD ["npm","start"]
EXPOSE 5000/tcp
```

10.	Go to k8s directory, modify deployment.yaml file, image line, the image will use AWS ECR `dancing-queen:latest` image after built
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dancingqueen-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dancingqueen-web
  template:
    metadata:
      labels:
        app: dancingqueen-web
    spec:
      containers:
        - command:
            - npm
            - start
          image: 870472129713.dkr.ecr.us-east-1.amazonaws.com/dancing-queen:latest
          imagePullPolicy: Always
          name: dancing-queen-web
          ports:
            - containerPort: 5000
```
11.	Generate Access Key for CodeCommit

Go to IAM --> User --> your user --> Security Credential Tab --> HTTPS Git credentials for CodeCommit.
Click Generate credentials and remember your access key ID and access key secret

![Admin](./.github/workflows/1.png)
12.	Create CodeCommit repository
```
cloud_user@chauphan1c:~/DancingQueen$ aws codecommit create-repository --repository-name dancing-queen
{
    "repositoryMetadata": {
        "accountId": "870472129713",
        "repositoryId": "2fee4cfc-7ae0-469c-a15e-591d6675ecce",
        "repositoryName": "dancing-queen",
        "lastModifiedDate": "2021-01-11T08:17:49.239000+00:00",
        "creationDate": "2021-01-11T08:17:49.239000+00:00",
        "cloneUrlHttp": "https://git-codecommit.us-east-1.amazonaws.com/v1/repos/dancing-queen",
        "cloneUrlSsh": "ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/dancing-queen",
        "Arn": "arn:aws:codecommit:us-east-1:870472129713:dancing-queen"
    }
}
```
13.	Put local dancing queen repository to AWS CodeCommit
```
git push https://git-codecommit.us-east-1.amazonaws.com/v1/repos/dancing-queen
Use the access key ID and token you create on above step
```
```
cloud_user@chauphan1c:~/DancingQueen$ git push https://git-codecommit.us-east-1.amazonaws.com/v1/repos/dancing-queen
Username for 'https://git-codecommit.us-east-1.amazonaws.com': 
Password for 'https://cloud_user-at-870472129713@git-codecommit.us-east-1.amazonaws.com':
Counting objects: 92, done.
Delta compression using up to 2 threads.
Compressing objects: 100% (81/81), done.
Writing objects: 100% (92/92), 86.02 MiB | 11.89 MiB/s, done.
Total 92 (delta 10), reused 0 (delta 0)
To https://git-codecommit.us-east-1.amazonaws.com/v1/repos/dancing-queen
 * [new branch]      main -> main
cloud_user@chauphan1c:~/DancingQueen$
```
14.	Create CodeBuild 

##### Source provider : AWS CodeCommit, repository: dancing-queen

![Admin](./.github/workflows/2.png)


##### Choose the operating system, runtime and image

> Make sure that you checked the tick box “Enable this flag if you want to build Docker Image … ”

![Admin](./.github/workflows/3.png)

15.	At the Build Command, chose Insert Build command and Switch to Editor
 
![Admin](./.github/workflows/4.png)

16.	Put the buildspec.yaml file, make sure the ECR and repository name is correct
```
version: 0.2
env:
  variables:
      AWS_REGION: "us-east-1"
      AWS_ECR: "870472129713.dkr.ecr.us-east-1.amazonaws.com"
      IMAGE_REPO_NAME: "dancing-queen"
      IMAGE_TAG: "latest"
  #parameter-store:
     # key: "value"
     # key: "value"
  #secrets-manager:
     # key: secret-id:json-key:version-stage:version-id
     # key: secret-id:json-key:version-stage:version-id
  #exported-variables:
     # - variable
     # - variable
  #git-credential-helper: yes
#batch:
  #fast-fail: true
  #build-list:
  #build-matrix:
  #build-graph:
phases:
  #install:
    #If you use the Ubuntu standard image 2.0 or later, you must specify runtime-versions.
    #If you specify runtime-versions and use an image other than Ubuntu standard image 2.0, the build fails.
    #runtime-versions:
      # name: version
      # name: version
   # commands:
  pre_build:
    commands:
       - echo "Login to AWS ECR"
       - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ECR
  build:
    commands:
      - docker build -t $IMAGE_REPO_NAME:$IMAGE_TAG .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ECR/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image...
      - docker push $AWS_ECR/$IMAGE_REPO_NAME:$IMAGE_TAG
```
17.	Check the service role of the CodeBuild, we will add policy to allow it write to AWS ECR

![Admin](./.github/workflows/5.png)

##### Click to it and go to IAM console, add policy

![Admin](./.github/workflows/6.png)
 
##### Choose ECR Power User and click attach policy, it allows CodeBuild to write your created image to AWS ECR

![Admin](./.github/workflows/15.png) 

18.	Create CodePipeline EKS-CICD

![Admin](./.github/workflows/7.png)

##### Source stage refer to AWS CodeCommit repository

![Admin](./.github/workflows/8.png)
 
##### Add build stage refer to CodeBuild project we created.
 
![Admin](./.github/workflows/9.png)

##### Skip the deploy stage, we will use Build stage in next

![Admin](./.github/workflows/10.png) 

###### And Create Pipeline

19.	Try to change code in CodeCommit and see the build stage trigger, build new image and put the latest image to AWS ECR
 
![Admin](./.github/workflows/11.png) 

##### Click Details and see the Build stage log
 
![Admin](./.github/workflows/12.png) 

##### Image is pushed successfully

![Admin](./.github/workflows/13.png) 

##### Summary: End of this step, we use CodeCommit with dancing-queen repository, use CodeBuild to build NodeJs application and create Docker image, put this image to AWS ECR and ready to use this image apply to AWS EKS.

![Admin](./.github/workflows/14.png) 

# Using CodeBuild buildspec.yaml to CI/CD apply to AWS EKS (cont.)
##### There are 02 options you can apply in this stage: 
##### 1. Using CodeBuild buildspec.yaml as a tricky stage to apply k8s manifest. 
##### 2. Using Lambda to to apply k8s manifest. 
##### I use option 1 :)

1.	Create new Role with Trust Policy codebuild.amazonaws.com and Policy “Describe Cluster”
The purpose of this role creation: this role allows CodeBuild to run kubectl apply -f <file>.yaml to EKS

![Admin](./.github/workflows/1-1.png) 

### Next step

![Admin](./.github/workflows/1-3.png) 

### Next step

![Admin](./.github/workflows/1-2.png)

### Next step

![Admin](./.github/workflows/1-4.png)

### Next step

![Admin](./.github/workflows/1-5.png)

### Next step

![Admin](./.github/workflows/1-6.png)

### End

20.	Create CodeBuild project name “Deploy” with the Role name we’ve already created.

![Admin](./.github/workflows/1-7.png)

21.	Edit the buildspec.yaml file as below
Make sure the EKS_NAME, AWS_ECR, IMAGE_REPO_NAME is correct
```
version: 0.2
env:
  variables:
     EKS_NAME: "floral-sheepdog-1610350243"
     AWS_REGION: "us-east-1"
     AWS_ECR: "870472129713.dkr.ecr.us-east-1.amazonaws.com"
     IMAGE_REPO_NAME: "dancing-queen"
     IMAGE_TAG: "latest"
     # key: "value"
  #parameter-store:
     # key: "value"
     # key: "value"
  #secrets-manager:
     # key: secret-id:json-key:version-stage:version-id
     # key: secret-id:json-key:version-stage:version-id
  #exported-variables:
     # - variable
     # - variable
  #git-credential-helper: yes
#batch:
  #fast-fail: true
  #build-list:
  #build-matrix:
  #build-graph:
phases:
  #install:
    #If you use the Ubuntu standard image 2.0 or later, you must specify runtime-versions.
    #If you specify runtime-versions and use an image other than Ubuntu standard image 2.0, the build fails.
    #runtime-versions:
      # name: version
      # name: version
    #commands:
       #- apt update
      # - command
  #pre_build:
    #commands:
      # - command
      # - command
  build:
    commands:
      - aws eks --region $AWS_REGION update-kubeconfig --name $EKS_NAME
      - kubectl apply -f ./k8s/deployment.yaml -f ./k8s/service.yaml
  #post_build:
    #commands:
      # - command
      # - command
#reports:
  #report-name-or-arn:
    #files:
      # - location
      # - location
    #base-directory: location
    #discard-paths: yes
    #file-format: JunitXml | CucumberJson
#artifacts:
  #files:
    # - location
    # - location
  #name: $(date +%Y-%m-%d)
  #discard-paths: yes
  #base-directory: location
#cache:
  #paths:
    # - paths
```
22.	Edit aws config map of EKS and add new role to RBAC of EKS cluster
The mapRoles below is: hey, k8s, with the role CodeBuild-EKS-Role, please map it to username: cloud-admin and group: system-masters in k8s priviledges.

##### kubectl edit configmaps aws-auth -n kube-system
```
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::870472129713:role/eksctl-floral-sheepdog-1610350243-NodeInstanceRole-M2CVM3ZT4LZI
      username: system:node:{{EC2PrivateDNSName}}
    - groups:
      - system:masters
      rolearn: arn:aws:iam::870472129713:role/CodeBuild-EKS-Role
      username: cloud-admin

kind: ConfigMap
metadata:
  creationTimestamp: "2021-01-11T07:50:37Z"
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:data:
        .: {}
        f:mapRoles: {}
    manager: vpcLambda
    operation: Update
    time: "2021-01-11T07:50:37Z"
  name: aws-auth
  namespace: kube-system
  resourceVersion: "1239"
  selfLink: /api/v1/namespaces/kube-system/configmaps/aws-auth
  uid: 6eafbc5e-0b31-413d-82d6-ac76fc525350
```
23.	Try to run new CodeBuild and see the logs

![Admin](./.github/workflows/1-8.png)
 
24.	Edit the CodePipeline to add Deploy stage
 
![Admin](./.github/workflows/1-9.png)
 
Add stage and action group “Deploy”
 
![Admin](./.github/workflows/1-10.png)

![Admin](./.github/workflows/1-11.png)

Done and Save new Pipeline

![Admin](./.github/workflows/1-12.png)

25.	Change the code at git, commit, push it to AWS CodeCommit and see the code is built and deployed to AWS EKS! 😊



