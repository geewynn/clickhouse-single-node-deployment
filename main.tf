# Create a new server running debian
resource "hcloud_server" "node1" {
  name        = var.server_name
  image       = var.image_type
  server_type = var.server_type
  firewall_ids = [hcloud_firewall.serverfirewall.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  ssh_keys = [hcloud_ssh_key.main.id]
}

resource "hcloud_ssh_key" "main" {
  name       = "my-sshkey"
  public_key = file(var.sshkey_file)
}


resource "hcloud_firewall" "serverfirewall" {
  name = "default_firewall"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = var.source_ips
  }

  # SSH access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = var.source_ips

  }

  # Clickhouse access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9000"
    source_ips = var.source_ips
    
  }

  # Clickhouse access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "8123"
    source_ips = var.source_ips
    
  }

  # Clickhouse access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9363"
    source_ips = var.source_ips
    
  }

  # Grafana access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "3000"
    source_ips = var.source_ips
    
  }

  # prometheus access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9090"
    source_ips = var.source_ips
    
  }

  # node exporter access
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9100"
    source_ips = var.source_ips
    
  }

}

resource "null_resource" "server_setup" {
  depends_on = [hcloud_server.node1]

  connection {
    type        = "ssh"
    host        = hcloud_server.node1.ipv4_address
    user        = var.node_user
    private_key = file(var.sshkey_private_file)
    timeout     = "2m"
  }

  # Upload all scripts
  provisioner "file" {
    source      = "${path.module}/scripts/install_clickhouse.sh"
    destination = "/tmp/install_clickhouse.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_prometheus.sh"
    destination = "/tmp/install_prometheus.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_grafana.sh"
    destination = "/tmp/install_grafana.sh"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/install_node_exporter.sh"
    destination = "/tmp/install_node_exporter.sh"
  }

  # Run all scripts in order
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_*.sh",
      "sudo /tmp/install_clickhouse.sh",
      "sudo /tmp/install_prometheus.sh",
      "sudo /tmp/install_grafana.sh",
      "sudo /tmp/install_node_exporter.sh"
    ]
  }

  triggers = {
    always_run = "${timestamp()}"
  }
}
