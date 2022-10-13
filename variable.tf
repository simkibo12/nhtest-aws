#DATASOURCE#
variable "is_portal_vpc" {
  type = bool
  default = true
}
variable "is_portal_subnet" {
  type = bool
  default = true
}
variable "is_portal_sg" {
  type = bool
  default = true
}

#ATHEN#
variable "access_key" {}
variable "secret_key" {}

#NETWORK#
#variable "subnet_id" {} // false 시 주석
variable "vpc_name" {}
variable "cidr_block" {}
variable "new_subnet_cidr_blocks" {}

#SECURITY#
#variable "security_group_id" {} // false 시 주석
variable "security_group_name" {}
variable "security_group_description" {}
variable "security_group_tag" {}      // "Terraform aws security group test"
variable "security_group_rule"{

  type = map(object({
    type = string
    security_group_name = string
    from_port = number
    to_port = number
    cidr_blocks = list(string)
    protocol = string
  }))
}

#EC2#
variable "key_pair" {}

#FOR_EACH#

#EC2#
variable "ec2_instance" {
  type = map(object({
    vm_name = string
    os_disk_name = string
    ami            = string
    instance_type  = string
    os_volume_type = string
    os_volume_size = number
  }))
}

#EBS DISK(DATA DISK)#
variable "data_disk" {
  type = map(object({
    ec2_instance   = string  // ec2의 정보
    data_disk_name = string  
    data_device_name = string  // lun
    data_volume_availability_zone = string
    data_volume_type = string
    data_volume_size = number
  }))
}

variable "force_detach" {
  type = bool
}
