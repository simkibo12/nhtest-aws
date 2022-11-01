#NETWORK##

data "aws_subnet" "kibo-subnet-01" {
  count = var.is_portal_vpc == true ? 0 : 1
  id = "subnet-00c1b8261e962d8be"
}

data "aws_vpc" "selected" {
  id = "vpc-03eede61a3b2599e1"
}

data "aws_route_table" "portal_route_table" {
  count = var.is_portal_subnet == false ? 0 : 1
  route_table_id = "rtb-06a01e00dd5d0930d"
}


resource "aws_vpc" "new_vpc" {
  count = var.is_portal_vpc == false ? 1 : 0
  cidr_block           = var.cidr_block
# enable_dns_support   = true
# enable_dns_hostnames = true

  tags = {
  Name = var.vpc_name
  }
}

 

resource "aws_internet_gateway" "new_igw" {
  count = var.is_portal_vpc == false ? 1 : 0
  vpc_id = var.is_portal_vpc == false ? aws_vpc.new_vpc[0].id : data.aws_vpc.selected.id      
  }
  
  
resource "aws_route_table" "new_route_table" {
  count = var.is_portal_subnet == false ? 1 : 0
  vpc_id = var.is_portal_vpc == false ? aws_vpc.new_vpc[0].id : data.aws_vpc.selected.id
  route = []
  }
  
resource "aws_route" "new_route" {
  count = var.is_portal_vpc == false ? 1 : 0
  route_table_id         = aws_route_table.new_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.new_igw[0].id
  }
  
  
resource "aws_subnet" "new_subnet" {
  count = var.is_portal_subnet == false ? 1 : 0
  vpc_id                  = var.is_portal_vpc == false ? aws_vpc.new_vpc[0].id : data.aws_vpc.selected.id
  cidr_block              = var.is_portal_subnet == false ? var.new_subnet_cidr_blocks : data.aws_vpc.selected.id
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "true"
  }

resource "aws_subnet" "lb_subnet" {
  count = var.is_portal_subnet == false ? 1 : 0
  vpc_id                  = var.is_portal_vpc == false ? aws_vpc.new_vpc[0].id : data.aws_vpc.selected.id
  cidr_block              = var.is_portal_subnet == false ? var.lb_cidr_blocks : data.aws_vpc.selected.id
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = "true"
  }
  

  
  resource "aws_route_table_association" "new_subnet_route_table_association" {
    count = var.is_portal_subnet == false ? 1 : 0
    subnet_id      = aws_subnet.new_subnet[0].id
    route_table_id = var.is_portal_subnet == false ? aws_route_table.new_route_table[0].id : data.aws_route_table.portal_route_table[0].id
  }



#SECURITY#

data "aws_security_group" "kibo-sg" {
  count = var.is_portal_sg == false ? 0 : 1
  id = var.is_portal_sg == false ? var.security_group_id : 0
}


resource "aws_security_group" "sg" {
  count = var.is_portal_sg == false ? 1 : 0
  name = var.security_group_name
  description = var.security_group_description 
  vpc_id = var.is_portal_vpc == false ? aws_vpc.new_vpc[0].id : data.aws_vpc.selected.id         
  tags = { Name = var.security_group_tag }
}

resource "aws_security_group_rule" "sg_rule"{
  for_each = var.security_group_rule
  type = each.value.type
  security_group_id = aws_security_group.sg[0].id            
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  depends_on = [aws_security_group.sg]

}

#EC2#
data "aws_key_pair" "kibo-aws-key-pair" {
  key_name = var.key_pair
}


resource "aws_instance" "instance" {
  for_each      = var.ec2_instance
  ami           = each.value.ami
  instance_type = each.value.instance_type
  key_name      = data.aws_key_pair.kibo-aws-key-pair.key_name
  associate_public_ip_address = true
  subnet_id                   = var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.new_subnet[0].id
  vpc_security_group_ids      = var.is_portal_sg == true ? [data.aws_security_group.kibo-sg[0].id] : [aws_security_group.sg[0].id] 
  tags                        = {
     Name = each.value.vm_name  
     }           
  root_block_device {
  volume_type = each.value.os_volume_type
  volume_size = each.value.os_volume_size
    tags = {
      Name = each.value.os_disk_name
    }
  }  
  depends_on = [aws_security_group.sg,aws_security_group_rule.sg_rule]
}

resource "aws_ebs_volume" "data_disk" {
    for_each = var.data_disk
    availability_zone = each.value.data_volume_availability_zone
    type = each.value.data_volume_type
    size = each.value.data_volume_size
    tags = {
        Name = each.value.data_disk_name
    }
}

resource "aws_volume_attachment" "data_disk_attachment" {
  for_each = var.data_disk
  force_detach = var.force_detach
  device_name = each.value.data_device_name // azure = lun
  volume_id   = aws_ebs_volume.data_disk[each.key].id             
  instance_id = aws_instance.instance[each.value.ec2_instance].id
}

# S3 bucket

resource "aws_s3_bucket" "terraform-state" {
  bucket = "nh-terraform-bucket"


  versioning {
    enabled = true
  }
}

# object
resource "aws_s3_bucket_object" "object" {
  bucket = "nh-terraform-bucket"
  key    = "Folder1/"
  source = "/dev/null"
}


# ALB


resource "aws_lb" "nh_alb" {
  name               = "nh-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.is_portal_sg == true ? [data.aws_security_group.kibo-sg[0].id] : [aws_security_group.sg[0].id]
  #subnets            = [var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.new_subnet[0].id]
  #subnets            =  [for subnet in aws_subnet.new_subnet : subnet.id]

  
   subnet_mapping {
    subnet_id            = var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.new_subnet[0].id
    #private_ipv4_address = "10.0.1.15"
  }

 subnet_mapping {
    subnet_id            = var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.lb_subnet[0].id
    #private_ipv4_address = "10.0.2.15"
  }

  enable_deletion_protection = false
  
  tags = {
    Environment = "production"
  }
}

# LB

resource "aws_lb" "nh_nlb" {
  name               = "nh-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.new_subnet[0].id]



 enable_deletion_protection = false



 tags = {
    Environment = "production"
  }
}


# NGW

resource "aws_nat_gateway" "nat-gw" {
  connectivity_type = "private"
  subnet_id         = var.is_portal_subnet == true ? data.aws_subnet.kibo-subnet-01[0].id : aws_subnet.new_subnet[0].id
}


# TGW
resource "aws_ec2_transit_gateway" "transit-gw" {
    tags = {
        name = "nh-tgw-test"
    }
}
