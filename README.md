# initialbackend

This is a [Node.js](https://nodejs.org/) project 
​
## Project setup

1 > Replace this mongo db database url​ 👉 "mongodb+srv://dummy:dymmydb%40mongo@dummydb.cw083ce.mongodb.net/test" with your own mongo db url.

2 > use "http://localhost:5555/api" as base url in postman 


## This project is an assessment of my cloud infrastructure skills which involved using an Infrastructure as Code tool---Terraform for creating a Load Balancer in a public subnet which directs traffic to an AWS EC2 Instance in a private subnet, the EC2 Instance serves two containerized applications---a nodejs app container image and a nginx container image which are deployed to the Instance via a configuration management tool---Ansible.
![infrastructure_architecture](./infrastructure_architecture/infrastructure-architecture.png)

### Load Balancer DNS Endpoints:
- Nodejs App: http://node-alb-919790509.eu-north-1.elb.amazonaws.com:5555/ 
- Nginx: http://node-alb-919790509.eu-north-1.elb.amazonaws.com:8080/ 

### Given the two Load Balancer endpoints above, in a real life production environment, the endpoints should ideally be reachable as subdomains. 
- The endpoints above cannot be directly used with DNS Records in AWS Route53 as it doesn't work with a CNAME Record which works for hostnames as a subdomain(www.example.com) or an Alias Record which works for hostnames as root domain and subdomain(example.com and www.example.com); 
- To obtain suitable URLs for the endpoints which can be used as A-records in AWS Route53, associate the endpoints with CloudFront distributions using the Load Balancer DNS name as Origin;
- The CloudFront Distribution enables HTTPS Protocol and Web Application Firewall for the Load Balancer, note that the security group of the Load Balancer must allow the Public IPs of the CloudFront Distribution Edge Locations. 
- Add the subdomain you wish to use to reach the endpoints as an "Alternate domain name(CNAME)"--eg. test.nodeapi.space in the CloudFront configuration;
- Add a custom certificate(since we are using HTTPS) in your CloudFront configuration using AWS Certificate Manager or import your custom certificate;
- Repeat the steps for the other endpoint;
- Next, create a hosted zone with a domain name in Route53; create A-records for the two CloudFront Distributions based on the domain with an "Alias to CloudFront Distribution"; 
- The two containerized applications can be accessed via the following subdomains:
    - test.nodeapi.space
    - test.nginx.space

### Steps for creating an AWS EC2 Instance in a Private VPC Subnet
- Given the three default subnets of an AWS account are public subnets, create a load balancer in one of the three public subnets, the load balancer fronts our AWS EC2 Instance created in furthur steps.

- Create a private subnet in the default VPC with an attached availability zone, the private subnet is where we deploy the AWS EC2 Instance, the private subnet ip address can be derived by deducing its number across the default VPC and the three public subnets ip addresses.

- Create a NAT Gateway in the public subnet and associate it with an Elastic IP to provide internet access for the EC2 Instance in the private subnet.

- Create a Route Table for the private subnet to direct outbound traffic to the NAT Gateway in the public subnet.

- Associate the Route Table with the private subnet.

### Steps for running the python script as a CRON Job
- Ensure your python script is executable 
```
chmod +x checker_script.py
```

- Ensure CRON is running
```
service cron start
```
```
service cron enable
```
```
service cron status
```

- List Cron Jobs for the current user 
```
crontab -l
```

- Create a Cron Job for the python script using the command:`crontab -e`, the command launches the crontab file in edit mode, press `i` to edit the file

- Add the command to execute the python script every six hours:
`0 */6 * * * /usr/bin/python3 /mnt/c/Users/Tomiwa/Documents/cloud-devops-roadmap/terraform-docker-alb/checker_script.py`

- By default the output of the crontab jobs (including errors) is sent through the email of the user which the crontab file belongs to, however, you can specify an external email address that cron sends to with the `$MAILTO` variable. 
MAILTO=tomiwaaribisala@gmail.com

- Press `esc` to exit the editing mode

- Type `:wq` to save and quit the file; w means to write and q means quit.