# Set the variable value in *.tfvars file
# or using the -var="hcloud_token=..." CLI option
variable "hcloud_token" {
  sensitive = true
}


variable "server_name" {
    description = "your node name"
}

variable "image_type" {
    description = "ubuntu, debian.. etc"
}

variable "server_type" {
    description = "type of hetzner server cx22 etc"
}


variable "source_ips" {
    description = "source ip for firewall"
}


variable "sshkey_file" {
    description = "ssh key pub file"
}

variable "sshkey_private_file" {
    description = "ssh key private file"
}


variable "node_user" {
    description = "server user"
}



