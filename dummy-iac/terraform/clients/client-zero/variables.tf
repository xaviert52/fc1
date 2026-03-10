variable "project" {
  description = "Nombre del proyecto"
  type        = string
  default     = "pry"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "sandbox"
}

variable "aws_region" {
  description = "Región AWS"
  type        = string
  default     = "us-east-1"
}

variable "client_id" {
  description = "Identificador técnico del cliente o componente"
  type        = string
  default     = "client-zero"
}

variable "enable_service_discovery" {
  type    = bool
  default = true
}
