variable "unique_prefix" {
  description = <<-EOS
                Represents the unique prefix used for naming configuration entities.
                EOS
  type = string
}

variable "project_name" {
  description = <<-EOS
                Represents the project name used for naming configuration entities.
                EOS
  type = string
}

variable "instance_server_port" {
  description = <<-EOS
                Represents the port number on which listen instance server.
                EOS
  type = number
}

variable "asg_min_size" {
  description = <<-EOS
                Represents the min number of asg instances.
                EOS
  type = number
}

variable "asg_max_size" {
  description = <<-EOS
                Represents the max number of asg instances.
                EOS
  type = number
}

variable "instance_type" {
  description = <<-EOS
                Represents the type of instance used in asg group.
                EOS
  type = string
}

variable "db_address" {
  description = <<-EOS
                Represents the address of db.
                EOS
  type = string
}

variable "db_port" {
  description = <<-EOS
                Represents the port of db.
                EOS
  type = number
}