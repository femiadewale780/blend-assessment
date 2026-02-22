variable "name" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
}

variable "vpc_id" { type = string }

variable "alb_ingress_cidrs" { type = list(string) }
variable "container_port"    { type = number }
variable "db_port"           { type = number }
