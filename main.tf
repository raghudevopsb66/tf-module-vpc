resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.env}-vpc"
  }
}

module "subnets" {
  for_each = var.subnets
  source   = "./subnets"
  name     = each.value["name"]
  subnets  = each.value["subnet_cidr"]
  vpc_id   = aws_vpc.main.id
  AZ       = var.AZ
  ngw      = try(each.value["ngw"], false)
  igw      = try(each.value["igw"], false)
  env      = var.env
  //igw_id   = aws_internet_gateway.igw.id
  //route_tables = aws_route_table.route-tables
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_eip" "ngw" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = module.subnets["public"].out[0].id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "route-tables" {
  for_each = var.subnets
  vpc_id   = aws_vpc.main.id
  tags = {
    Name = "${each.value["name"]}-rt"
  }
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.route-tables["public"].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(module.subnets["public"].out[*].id)
  subnet_id      = element(module.subnets["public"].out[*].id, count.index)
  route_table_id = aws_route_table.route-tables["public"].id
}

resource "aws_route" "private-apps" {
  route_table_id         = aws_route_table.route-tables["apps"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_route" "private-db" {
  route_table_id         = aws_route_table.route-tables["db"].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.ngw.id
}

resource "aws_route_table_association" "apps" {
  count          = length(module.subnets["apps"].out[*].id)
  subnet_id      = element(module.subnets["apps"].out[*].id, count.index)
  route_table_id = aws_route_table.route-tables["apps"].id
}

resource "aws_route_table_association" "db" {
  count          = length(module.subnets["db"].out[*].id)
  subnet_id      = element(module.subnets["db"].out[*].id, count.index)
  route_table_id = aws_route_table.route-tables["db"].id
}

//resource "aws_route" "private-apps" {
//  route_table_id              = aws_route_table.route-tables["public"].id
//  destination_cidr_block = "0.0.0.0/0"
//  gateway_id  = aws_internet_gateway.igw.id
//}
//
//resource "aws_route" "private-db" {
//  route_table_id              = aws_route_table.route-tables["public"].id
//  destination_cidr_block = "0.0.0.0/0"
//  gateway_id  = aws_internet_gateway.igw.id
//}

output "out" {
  value = module.subnets["public"].out[*].id
}


