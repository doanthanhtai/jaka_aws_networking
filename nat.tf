###############################################
# Elastic IP for NAT Gateway
###############################################

resource "aws_eip" "nat_eip_1" {

  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-1"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_eip" "nat_eip_2" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip-2"
  }

  depends_on = [aws_internet_gateway.main]
}

###############################################
# NAT Gateway
###############################################

resource "aws_nat_gateway" "nat_gw_1" {

  allocation_id = aws_eip.nat_eip_1.id

  subnet_id = aws_subnet.public_1.id

  tags = {
    Name = "${local.name_prefix}-nat-1"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "nat_gw_2" {
  allocation_id = aws_eip.nat_eip_2.id

  subnet_id = aws_subnet.public_2.id

  tags = {
    Name = "${local.name_prefix}-nat-2"
  }

  depends_on = [aws_internet_gateway.main]
}
