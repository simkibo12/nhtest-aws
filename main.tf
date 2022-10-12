#NETWORK#
data "aws_subnet" "kibo-subnet-01" {
  id = var.subnet_id
}

#SECURITY#
data "aws_security_group" "kibo-sg" {
  id = var.security_group_id
}

#EC2#
data "aws_key_pair" "kibo-aws-key-pair" {
  key_name = var.key_pair
}

resource "aws_instance" "instance" {
  for_each      = var.ec2_instance
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = data.aws_key_pair.kibo-aws-key-pair.key_name
  associate_public_ip_address = true
  subnet_id                   = data.aws_subnet.kibo-subnet-01.id
  vpc_security_group_ids      = [data.aws_security_group.kibo-sg.id] // string required [] 필요
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
  #force_detach = var.force_detach
  device_name = each.value.data_device_name // azure = lun
  volume_id   = aws_ebs_volume.data_disk[each.key].id             //리소스 값
  instance_id = aws_instance.instance[each.value.ec2_instance].id //리소스 값
}
