# multi-arch-on-aws-with-karpenter
Configuration in this directory creates an AWS EKS cluster with Karpenter autoscaler using 1 nodepool that acomodates amd64 and arm64 architectures. Karpenter is provisioned on top of an EKS Managed Node Group and defaults to amd64 node types until a proper nodeselector is used to deploy a arm64 application.

spec:
      containers:
      - name: hello-world-arm64
        image: hello-world
        ports:
        - containerPort: 8080
      nodeSelector:
        kubernetes.io/arch: arm64

## Deploy
Initialize and create plan for the Terraform code

>terraform init
>terraform plan

Run Terraform Apply to provision into an existing VPC the EKS Cluster with Karpenter autoscaler.
>terraform apply 

Update the kubectl context to interact with the Amazon EKS cluster
>aws eks update-kubeconfig --name eks-multi-arch --region us-east-1

>./eks-node-viewer
2 nodes (500m/3860m) 13.0% cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ $0.192/hour | $140.160/month
10 pods (0 pending 10 running 10 bound)

ip-10-0-14-11.ec2.internal  cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960 On-Demand - Ready
ip-10-0-26-244.ec2.internal cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960 On-Demand - Ready

Verify the Karpenter installation by below command:
>kubectl get pods -n kube-system | grep karpenter

NAME                         READY   STATUS    RESTARTS   AGE
karpenter-7c5df57794-m5gjm   1/1     Running   0          5m
karpenter-7c5df57794-z5d24   1/1     Running   0          5m

## Test
Deploy an arm64 application using de deployment-arm64.yaml and explore the karpenter autoscaling using eks-node-viewer. 

>kubectl apply -f deployment-arm64.yaml
>./eks-node-viewer
3 nodes (500m/4800m) 10.4% cpu ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ $0.226/hour | $164.980/month
13 pods (3 pending 10 running 10 bound)

ip-10-0-14-11.ec2.internal  cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960   On-Demand - Ready
ip-10-0-26-244.ec2.internal cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960   On-Demand - Ready
i-0e1c63d1456a49b9b         cpu ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0% (0 pods) c6g.medium/$0.0340 On-Demand - NotReady/15s
You can notice Karpenter launched a c6g.medium instance to accommodate the arm64 workload.

kubectl scale deployment hello-world-arm64 --replicas=50
>./eks-node-viewer
4 nodes (800m/8720m) 9.2% cpu ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ $0.362/hour | $264.260/month
66 pods (45 pending 21 running 66 bound)

ip-10-0-14-11.ec2.internal  cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods)  m5.large/$0.0960   On-Demand - Ready
ip-10-0-26-244.ec2.internal cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods)  m5.large/$0.0960   On-Demand - Ready
ip-10-0-39-2.ec2.internal   cpu ██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  16% (8 pods)  c6g.medium/$0.0340 On-Demand - Ready
ip-10-0-45-251.ec2.internal cpu █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   4% (48 pods) c6g.xlarge/$0.1360 On-Demand - Ready
You can notice Karpenter launched a c6g.xlarge instance to accommodate 50 pending pods.

>kubectl scale deployment hello-world-arm64 --replica=3
>./eks-node-viewer
4 nodes (650m/8720m) 7.5% cpu ███░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ $0.362/hour | $264.260/month
16 pods (0 pending 16 running 16 bound)

ip-10-0-14-11.ec2.internal  cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960   On-Demand -        Ready
ip-10-0-26-244.ec2.internal cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960   On-Demand -        Ready
ip-10-0-45-251.ec2.internal cpu █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   4% (6 pods) c6g.xlarge/$0.1360 On-Demand Cordoned Ready
i-09d80a54af30e18e3         cpu ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   0% (0 pods) c6g.medium/$0.0340 On-Demand -        NotReady/8s
You can notice Karpenter closed the c6g.xlarge instance and launched one smaller to accommodate the remaining 3 pending pods in the hello-world-arm64 deployment.

>kubectl delete deployment hello-world-arm64
>./eks-node-viewer
2 nodes (500m/3860m) 13.0% cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ $0.192/hour | $140.160/month
10 pods (0 pending 10 running 10 bound)

ip-10-0-14-11.ec2.internal  cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960 On-Demand - Ready
ip-10-0-26-244.ec2.internal cpu █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  13% (5 pods) m5.large/$0.0960 On-Demand - Ready
You can notice Karpenter closed all the arm64 instances in the absence of any arm64 workload.

## Destroy
To avoid on-going costs, you can destroy the infrastructure using below command: 

>terraform destroy -auto-approve

## Existing VPC
If you want to deploy the EKS cluster into an existing VPC you need to prepare it first adding this resources.

>terraform state list | grep module.vpc

module.vpc.aws_default_network_acl.this[0]
module.vpc.aws_default_route_table.default[0]
module.vpc.aws_default_security_group.this[0]
module.vpc.aws_eip.nat[0]
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_nat_gateway.this[0]
module.vpc.aws_route.private_nat_gateway[0]
module.vpc.aws_route.public_internet_gateway[0]
module.vpc.aws_route_table.private[0]
module.vpc.aws_route_table.public[0]
module.vpc.aws_route_table_association.private[0]
module.vpc.aws_route_table_association.private[1]
module.vpc.aws_route_table_association.private[2]
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.public[1]
module.vpc.aws_route_table_association.public[2]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_subnet.private[2]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_subnet.public[2]
module.vpc.aws_vpc.this[0]
