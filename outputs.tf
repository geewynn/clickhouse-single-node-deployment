# Output the server IP address
output "server_ip" {
  value = hcloud_server.node1.ipv4_address
}