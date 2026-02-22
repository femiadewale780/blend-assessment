variable "name" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
}

variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "ecs_sg_id"          { type = string }

variable "container_port" { type = number }

variable "image_uri"     { type = string }
variable "desired_count" { type = number }
variable "cpu"           { type = number }
variable "memory"        { type = number }

variable "db_user" { type = string }

variable "db_secret_arn" { type = string }

variable "target_group_arn" { type = string }
