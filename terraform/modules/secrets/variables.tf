variable "name" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
}

variable "db_host"     { type = string }
variable "db_name"     { type = string }
variable "db_password" { type = string }
variable "db_port"     { type = number }
