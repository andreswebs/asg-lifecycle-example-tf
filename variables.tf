variable "name" {
  type = string
}

# variable "volume_delete" {
#   type    = bool
#   default = true
# }

# variable "volume_encrypted" {
#   type    = bool
#   default = true
# }

# variable "volume_size" {
#   type    = number
#   default = 50
# }

variable "instance_type" {
  type    = string
  default = "t3a.2xlarge"
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "cidr_whitelist" {
  type = list(string)
}

variable "monitoring_enabled" {
  type    = bool
  default = false
}
