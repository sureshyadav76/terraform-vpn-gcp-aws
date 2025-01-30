###################
#       GCP
###################

// Provisions an Ubuntu VM
resource "google_compute_instance" "default" {
  name         = "ubuntu"
  machine_type = "e2-micro"
  zone         = "europe-west3-a"

  tags = ["ubuntu"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = google_compute_network.vpn.name // Enables Private IP Address
    access_config {}                          // Enables Public IP Address
  }
}

// Provisions a VPC Network
resource "google_compute_network" "vpn" {
  name = "vpn-network"
}

// Provisions a Security Group - Egress
resource "google_compute_firewall" "egress-rules" {
  name        = "egress"
  network     = google_compute_network.vpn.name
  description = "Creates egress firewall rule targeting destination ranges"
  direction   = "EGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "1000-2000"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

// Provisions a Security Group - Ingress
resource "google_compute_firewall" "ingress-rules" {
  name        = "ingress"
  network     = google_compute_network.vpn.name
  description = "Creates ingress firewall rule targeting destination ranges"
  direction   = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Provisions an External IP Address
resource "google_compute_address" "vpn_static_ip" {
  name = "vpn-static-ip"
}

// Provisions a VPN Gateway
resource "google_compute_vpn_gateway" "target_gateway" {
  name    = "vpn-network"
  network = google_compute_network.vpn.id
}

# Tunnel creation requires the following rules to approve
// Creating Forwarding Rules
resource "google_compute_forwarding_rule" "fr_esp" {
  name        = "fr-esp"
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp500" {
  name        = "fr-udp500"
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

resource "google_compute_forwarding_rule" "fr_udp4500" {
  name        = "fr-udp4500"
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_static_ip.address
  target      = google_compute_vpn_gateway.target_gateway.id
}

// Provision VPN Tunnel # 1
resource "google_compute_vpn_tunnel" "vpn-1" {
  name                    = "vpn-1"
  peer_ip                 = aws_vpn_connection.main.tunnel1_address
  shared_secret           = aws_vpn_connection.main.tunnel1_preshared_key
  remote_traffic_selector = [aws_vpc.network.cidr_block]
  local_traffic_selector  = ["0.0.0.0/0"] // VPN tunnel is set as Policy Based in the GUI but with a local network to 0.0.0.0/0, thus technically equivalent to Route Based config.
  ike_version             = 1

  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.id

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

// Provision VPN Tunnel # 2
resource "google_compute_vpn_tunnel" "vpn-2" {
  name                    = "vpn-2"
  peer_ip                 = aws_vpn_connection.main.tunnel2_address
  shared_secret           = aws_vpn_connection.main.tunnel2_preshared_key
  remote_traffic_selector = [aws_vpc.network.cidr_block]
  local_traffic_selector  = ["0.0.0.0/0"] // VPN tunnel is set as Policy Based in the GUI but with a local network to 0.0.0.0/0, thus technically equivalent to Route Based config.
  ike_version             = 1

  target_vpn_gateway = google_compute_vpn_gateway.target_gateway.id

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

// Provision a GCP Route - Tunnel1
resource "google_compute_route" "route1" {
  name       = "aws-route-tunnel1"
  network    = google_compute_network.vpn.name
  dest_range = aws_vpc.network.cidr_block
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.vpn-1.id
}

// Provision a GCP Route - Tunnel2
resource "google_compute_route" "route2" {
  name       = "aws-route-tunnel2"
  network    = google_compute_network.vpn.name
  dest_range = aws_vpc.network.cidr_block
  priority   = 1000

  next_hop_vpn_tunnel = google_compute_vpn_tunnel.vpn-2.id
}



###################
#       AWS
###################

// Provisions a VPC
resource "aws_vpc" "network" {
  cidr_block = var.aws_vpc_cidr

  tags = {
    Name = "vpn-vpc"
  }
}

// Provisions a Subnet - Receives a Public IP on launch
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.network.id
  cidr_block              = aws_vpc.network.cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "vpn-subnet"
  }
}

// Provisions an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = "GW-VPN-VPC"
  }
}

// Provisions a Routing Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  # Routing GCP VPC CIDR to VPN Gateway
  route {
    gateway_id = aws_vpn_gateway.vpn_gw.id
    cidr_block = var.subnet_europe_west3 // "10.156.0.0/20" - Default VPC CIDR for 'europe-west3'
    # For more on VPC CIDR visit the link
    # https://console.cloud.google.com/networking/networks/details/default?{YOUR-PROJECT-NAME-HERE}&pageTab=SUBNETS // Change {YOUR-PROJECT-NAME-HERE}
  }

  tags = {
    Name = "RT-VPN-VPC"
  }
}

// Provisions a Route Table Association - Serves as a Bridge for Subnet
resource "aws_route_table_association" "rt" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}

// Defaults a route table
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.network.id
  route_table_id = aws_route_table.rt.id
}

// Provisions a Customer Gateway with GCP's External IP Attached
resource "aws_customer_gateway" "customer_gateway" {
  device_name = "AWS-CG"
  bgp_asn     = 65000
  ip_address  = google_compute_address.vpn_static_ip.address
  type        = "ipsec.1"

  tags = {
    Name = "AWS-CG"
  }
}

// Provisions a Virtual Private Gateway attached to a VPC
resource "aws_vpn_gateway" "vpn_gw" {
  vpc_id = aws_vpc.network.id

  tags = {
    Name = "AWS-VPG"
  }
}

// Provisions a Site-to-Site VPC Connection
resource "aws_vpn_connection" "main" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gw.id
  customer_gateway_id = aws_customer_gateway.customer_gateway.id
  type                = "ipsec.1"
  static_routes_only  = true

  tags = {
    Name = "VPN Connection"
  }
}

// Provides a static route between a VPN connection and a customer gateway.
resource "aws_vpn_connection_route" "main" {
  vpn_connection_id      = aws_vpn_connection.main.id
  destination_cidr_block = var.subnet_europe_west3 // "10.156.0.0/20" - Default VPC CIDR for 'europe-west3' & For more on Subnet CIDR visit the link
  # https://console.cloud.google.com/networking/networks/details/default?{YOUR-PROJECT-NAME-HERE}&pageTab=SUBNETS // Change {YOUR-PROJECT-NAME-HERE}
}

resource "aws_security_group" "gcp" {
  name        = "GCP Connection"
  description = "Allow GCP VPN Connection"
  vpc_id      = aws_vpc.network.id

  // Default SSH Connectivity to allow AWS Console connection'
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allows Ingress ICMP (Ping) from GCP Subnet CIDR 'europe-west3'
  ingress {
    description = "ICMP from GCP Subnet"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.subnet_europe_west3] // 'europe-west3' GCP Region
  }

  // External Communication
  egress {
    description      = "External Communication"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "GCP-VPN"
  }
}

// Provisions the latest Ubuntu Image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

// Provision an EC2 Instance - Ubuntu OS
resource "aws_instance" "ec2" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.ubuntu.id
  vpc_security_group_ids = [aws_security_group.gcp.id]
  subnet_id              = aws_subnet.public_subnet.id

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "ubuntu-node"
  }
}