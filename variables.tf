variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
}

variable "zone_name" {
  description = "Define zone name you would like to keep clean by lambda"
  default     = ""
}

variable "zone_id" {
  description = "Define zone id you would like to keep clean by lambda DEPRECATED"
  default     = ""
}