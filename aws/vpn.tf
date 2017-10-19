resource "aws_customer_gateway" "default" {
  bgp_asn    = 65000
  ip_address = "${var.vpn_peer_ip}"
  type       = "ipsec.1"
  tags {
    Name = "${var.prefix}-cust-gw"
  }
}

resource "aws_vpn_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name = "${var.prefix}-vpn-gw"
  }
}

resource "aws_vpn_gateway_attachment" "default" {
  vpc_id         = "${aws_vpc.main.id}"
  vpn_gateway_id = "${aws_vpn_gateway.default.id}"
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  vpn_gateway_id = "${aws_vpn_gateway.default.id}"
  route_table_id = "${aws_route_table.private.*.id[count.index]}"
}

resource "aws_vpn_connection" "default" {
  vpn_gateway_id      = "${aws_vpn_gateway.default.id}"
  customer_gateway_id = "${aws_customer_gateway.default.id}"
  type                = "ipsec.1"
  static_routes_only  = true
  tags {
    Name = "${var.prefix}-vpn-conn"
  }
}

resource "aws_vpn_connection_route" "default" {
  destination_cidr_block = "${var.remote_ip_range}"
  vpn_connection_id      = "${aws_vpn_connection.default.id}"
}

output "vpn_ip" {
  value = "${aws_vpn_connection.default.tunnel1_address}"
}

output "vpn_preshared_key" {
  value = "${aws_vpn_connection.default.tunnel1_preshared_key}"
}
