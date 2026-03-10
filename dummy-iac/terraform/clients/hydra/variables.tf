variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  default = "pry"
}

variable "environment" {
  default = "sandbox"
}

variable "system_secret" {
  description = "Secreto de sistema para encriptación de datos en reposo"
  type        = string
  sensitive   = true
}


variable "enable_service_discovery" {
  type    = bool
  default = true
}
