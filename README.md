# initialbackend

This is a [Node.js](https://nodejs.org/) project 
​
## Project setup

1 > Replace this mongo db database url​ 👉 "mongodb+srv://dummy:dymmydb%40mongo@dummydb.cw083ce.mongodb.net/test" with your own mongo db url.

2 > use "http://localhost:5555/api" as base url in postman 


## Steps for creating an AWS EC2 Instance in a Private VPC Subnet
- Given the three default subnets of an AWS account are public subnets, create a load balancer in one of the three public subnets, the load balancer fronts our AWS EC2 Instance created in furthur steps.
- Create a private subnet in the default VPC with an attached Availability Zone where we deploy the AWS EC2 Instance, the private subnet ip address can be derived by deducing its number across the VPC and the three public subnets ip addresses.
- Create a NAT Gateway in the public subnet and associate it with an Elastic IP to provide internet access for the EC2 Instance in the private subnet.
- Create a Route Table for the private subnet to direct outbound traffic to the NAT Gateway in the public subnet.
- Associate the Route Table with the private subnet.

## Steps for running the python checker script locally
- Install Python 
```
sudo apt install python3 
```

- Install Python Packages 
```
python -m pip install boto3
```
```
python -m pip install os
```
```
python -m pip install time
```

- Execute the script:
```
python checker_script.py
```