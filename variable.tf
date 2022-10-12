#ATHEN#
variable "access_key" {}
variable "secret_key" {}

#NETWORK#
variable "subnet_id" {}

#SECURITY#
variable "security_group_id" {}

#EC2#
variable "ami" {}
variable "instance_type" {}
variable "key_pair" {}

#FOR_EACH#

#EC2#
variable "ec2_instance" {
  type = map(object({
    vm_name = string
    os_disk_name = string
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


#variable "force_detach" {
#  type = bool
#}
