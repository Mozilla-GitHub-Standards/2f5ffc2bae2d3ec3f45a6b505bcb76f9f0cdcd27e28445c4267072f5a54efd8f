/*
This file defines the shared VPC configurations including VPNs
*/

# Define VPC for vpn to scl3
resource "aws_vpc" "primary_vpc" {
    # This is a NetOps sanctioned cidr block - see bug 1272453
    cidr_block = "10.191.4.0/24"

    tags {
        Name = "vpn-vpc"
    }
}

# Add primary igw route
resource "aws_route" "route_all_rt_rule" {
    route_table_id = "${aws_vpc.primary_vpc.main_route_table_id}"
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.primary_igw.id}"
}

# Establish a primary internet gateway
resource "aws_internet_gateway" "primary_igw" {
    vpc_id = "${aws_vpc.primary_vpc.id}"

    tags {
        Name = "Primary Internet Gateway"
        Name = "vpn_vpc-igw"
    }
}

# Setup VPN connection SCL3 <--> VPC
module "vpn" {
  source = "../modules/tf_aws_vpn"

  name = "mozreview"
  vpc_id = "${aws_vpc.primary_vpc.id}"

  main_route_table_id = "${aws_vpc.primary_vpc.main_route_table_id}"

  vpn_bgp_asn = "65022"
  vpn_ip_address = "63.245.214.100"
  vpn_dest_cidr_block = "10.0.0.0/8"
}

module "bastion_vpc" {
    source = "../modules/tf_aws_vpc"

    name = "bastion-vpc"
    cidr = "${var.bastion_cidr}"
    public_subnets = "${var.bastion_cidr}"
    azs_public = "us-west-2a"
}

module "bastion_to_vpn-vpx" {
    source = "../modules/tf_vpc_peer"

    name = "bastion_to_vpn"
    requester_vpc_id = "${module.bastion_vpc.vpc_id}"
    requester_route_table_id = "${module.bastion_vpc.public_route_table_id}"
    requester_cidr_block = "${var.bastion_cidr}"
    peer_vpc_id = "${aws_vpc.primary_vpc.id}"
    peer_route_table_id = "${aws_vpc.primary_vpc.main_route_table_id}"
    peer_cidr_block = "${aws_vpc.primary_vpc.cidr_block}"
    peer_account_id = "${var.account_id}"
}
