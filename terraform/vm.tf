provider "aws" {
    region  = "us-east-2"
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
data "aws_ami_ids" "Jenkins-ec2" {
    owners           = ["self"]

    filter {
        name   = "tag:Name"
        values = ["Jenkins-ec2"]
    }
}
resource "aws_vpc" "jenkins-ap" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
      "Name" = "eksDemo-ap"
  }
}
resource "aws_subnet" "jenkins" {
  availability_zone       = "us-east-2a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.jenkins-ap.id

  tags = {
      "Name" = "subnet-1"
  }
}
resource "aws_internet_gateway" "jenkins-ap" {
  vpc_id = aws_vpc.jenkins-ap.id

  tags = {
    Name = "eksDemoIgw-ap"
  }
}
resource "aws_route_table" "jenkins" {
  vpc_id = aws_vpc.jenkins-ap.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins-ap.id
  }
}
resource "aws_route_table_association" "jenkins" {
  subnet_id      = aws_subnet.jenkins.id
  route_table_id = aws_route_table.jenkins.id
}
resource "aws_security_group" "jenkinsSG" {
  vpc_id      = aws_vpc.jenkins-ap.id  

ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }    
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkinsSG"
  }
}
resource "aws_instance" "my_first_tf_instance-ap" {
  ami = "ami-0385de7a55d0de70f"
  instance_type = "t2.large"
  key_name = "vara3"
  subnet_id = aws_subnet.jenkins.id
  vpc_security_group_ids = [ aws_security_group.jenkinsSG.id ]
  tags = {
    "Name" = "eks-demo-jenkins-ap"
    } 
    provisioner "remote-exec" {
        inline = [
            "echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo",
           // "wget -O /tmp/pre_install.yml https://github.com/cloudsavara/eks-demo-project/blob/main/pre_install.yml",
           // "ansible-playbook -u centos /tmp/pre_install.yml",
           // "wget -O /tmp/installvault.sh https://github.com/cloudsavara/eks-demo-project/blob/main/vault_install.sh",
           // "sudo chmod +x /tmp/installvault.sh",
           // "sudo sh /tmp/installvault.sh"
        ]
        connection {
            type = "ssh"
            host = self.public_ip
            user = "centos"
            private_key = file("vara3.pem")
        }
    }
}
output "Jenkins" {
    value = aws_instance.my_first_tf_instance-ap.public_ip
}