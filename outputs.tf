output "gcp_reserved_ip" { value = google_compute_address.vpn_static_ip.address }
output "tunnel_status_2" { value = google_compute_vpn_tunnel.vpn-1.detailed_status }
output "tunnel_status_1" { value = google_compute_vpn_tunnel.vpn-2.detailed_status }
output "gcp_instance_ip" { value = [for k in google_compute_instance.default.network_interface : k.network_ip] }
output "aws_instance_ip" { value = aws_instance.ec2.public_ip }
output "aws_vpc_cidr" { value = aws_vpc.network.cidr_block }
