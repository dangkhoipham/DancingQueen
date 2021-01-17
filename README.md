# How to apply CI/CD to AWS Kubernetes
#### This is the demo how to build and apply an web nodejs application to AWS Kubernetes cluster using CodeCommit, CodeBuilt and CodePipeline
## Create AWS EKS using eksctl
### I would like to use eksctl to create AWS EKS for the demo, but you feel free to create it using any tool you'd like, for ex: kops, kubeadm, Terraform, CloudFormation
#### You need to have bastion host or laptop with docker, kubectl and AWS CLI installed.
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
4.	Check if the node:6 images is available, if not, pull it from Docker Hub by command `docker pull node:lastest`
##### You should run the node js on AWS ECR, because each time you build, you don't waste time and bandwidth to download it from Docker Hub again, and it will lead to alarm *limit resource* from Docker
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
