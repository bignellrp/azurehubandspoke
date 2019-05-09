variable "location" {
  description = "Location of the network"
  default     = "uksouth"
}

variable "username" {
  description = "Username for Virtual Machines"
  default     = "adminpoc"
}

variable "password" {
  description = "Password for Virtual Machines"
  default     = "Qwerty123456"
}

variable "vmsize" {
  description = "Size of the VMs"
  default     = "Standard_DS1_v2"
}
