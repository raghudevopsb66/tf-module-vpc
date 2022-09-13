resource "aws_route_table" "route-tables" {
  vpc_id = var.vpc_id
  tags = {
    Name = "${var.name}-rt"
  }
}

resource "aws_route_table_association" "assoc" {
  count          = length(var.subnet_ids[var.name].subnet_ids)
  subnet_id      = element(var.subnet_ids[var.name].subnet_ids, count.index)
  route_table_id = aws_route_table.route-tables.id
}

resource "local_file" "foo" {
  content  = length(var.subnet_ids[var.name].subnet_ids)
  filename = "/tmp/out"
}

//output "out" {
//  value = jsonencode(var.subnet_ids[var.name])
//}

