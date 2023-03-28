# Create a VPC
resource "aws_vpc" "WPvpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
    Name = "WPVPC"
    }
}

resource "aws_internet_gateway" "igw" {
  tags = {
    Name = "main"
  }
}
resource "aws_internet_gateway_attachment" "igwattachment" {
  internet_gateway_id = aws_internet_gateway.igw.id
  vpc_id              = aws_vpc.WPvpc.id
}

# Create a route table for the public subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.WPvpc.id

  # Create a route to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate the public route table with the public subnet
resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_eip" "NAT_EIP" {
  vpc = true
}

resource "aws_nat_gateway" "privateinstanceNAT" {
  allocation_id = aws_eip.NAT_EIP.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "WP NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create a route table for the private subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.WPvpc.id

  # Create a route to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.privateinstanceNAT.id
  }

  tags = {
    Name = "private-rt"
  }
}

#associate NAT Gateway to private subnets
resource "aws_route_table_association" "nat_gateway_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "nat_gateway_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
