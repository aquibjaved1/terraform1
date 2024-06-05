Terraform Task:
Create VPC
Create Internet gateway
Create Custom Route Table
Create Subnet
Associate subnet with Route Table
Create Security Group to allow port 22.80,443
Create a network interface with an ip in the subnet that was created in step 4
Assign an elastic IP to the network interface created in step 7
Create Ubuntu server and install/enable apache2

Note:

Create single main.tf which will be created the above resources and do not hardcode the id's.
Configure s3 as backend and dynamo db locking for multi user execution.
