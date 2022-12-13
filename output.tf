output "access_key" {
value = var.access_key
}
variable "secret_key" {
value = var.secret_key
sensitive = true
}
