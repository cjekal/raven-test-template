variable "vpc_id" {
  type    = string
  default = "vpc-ea5f3d81"
}

variable "url" {
  type    = string
  default = "springboot-server.raven.lightfeathersandbox.com"
}

variable "subnets" {
  type    = list(string)
  default = ["subnet-905bd1fb", "subnet-ff3fff82", "subnet-c04a618c"]
}

variable "vpc_subnets" {
  type    = list(string)
  default = ["subnet-c04a618c", "subnet-ff3fff82", "subnet-905bd1fb"]
}

variable "subnets_cidrs" {
  type    = list(string)
  default = ["172.31.32.0/20", "172.31.16.0/20", "172.31.0.0/20"]
}

variable "zone_id" {
  type    = string
  default = "Z051626945ZBJUMUIBYM"
}

variable "nodeport" {
  type = string
}

variable "instance_ids" {
  type = list(string)
}