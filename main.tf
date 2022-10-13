#NETWORK#

data "aws_subnet" "kibo-subnet-01" {
  count = var.is_portal_vpc == false ? 0 : 1
  id = var.subnet_id
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
  vpc_id = aws_vpc.new_vpc[0].id
  }
  
  
resource "aws_route_table" "new_route_table" {
  count = var.is_portal_vpc == false ? 1 : 0
  vpc_id = aws_vpc.new_vpc[0].id
  }
  
resource "aws_route" "new_route" {
  count = var.is_portal_vpc == false ? 1 : 0
  route_table_id         = aws_route_table.new_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.new_igw[0].id
  }
  
  
resource "aws_subnet" "new_subnet" {
  count = var.is_portal_subnet == false ? 1 : 0
  vpc_id                  = aws_vpc.new_vpc[0].id
  cidr_block              = var.new_subnet_cidr_blocks
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = "true"
  
  }
  
  
  resource "aws_route_table_association" "new_subnet_route_table_association" {
    count = var.is_portal_subnet == false ? 1 : 0
    subnet_id      = aws_subnet.new_subnet[0].id
    route_table_id = aws_route_table.new_route_table[0].id
  }



#SECURITY#

data "aws_security_group" "kibo-sg" {
  count = var.is_portal_sg == false ? 0 : 1
  id = var.security_group_id
}


resource "aws_security_group" "sg" {
  count = var.is_portal_sg == false ? 1 : 0
  name = var.security_group_name
  description = var.security_group_description //"Allow TLS inbound traffic"
  vpc_id = aws_vpc.new_vpc[0].id                      // vpc id 필요             >>>> 수정 필요
  tags = { Name = var.security_group_tag }
}

resource "aws_security_group_rule" "sg_rule"{
  for_each = var.security_group_rule
  type = each.value.type
  security_group_id = aws_security_group.sg[0].id            //              >>>> 수정 필요
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
  vpc_security_group_ids      = var.is_portal_sg == true ? [data.aws_security_group.kibo-sg[0].id] : [aws_security_group.sg[0].id] // string required [] 필요
  tags                        = {
     Name = each.value.vm_name  // Name으로 해야 ec2 네임이 생성됨............name으로 하면 tag에만 보이고 네임이 없는 ec2가... 생성됨..
     }     //each.key로 하면 key값을 보고 NAME, tag가 생성됨  ec2_01,02 이렇게.. value의 vm_name으로 해야한다.          
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
  volume_id   = aws_ebs_volume.data_disk[each.key].id             //리소스 값
  instance_id = aws_instance.instance[each.value.ec2_instance].id //리소스 값
}
