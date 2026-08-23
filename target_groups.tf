resource "aws_lb_target_group" "payment_tg" {
  name     = "${local.name_prefix}-payment-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled  = true
    path     = "/api/payments/actuator/health"
    protocol = "HTTP"
    port     = "traffic-port"
  }
  tags = {
    Name = "${local.name_prefix}-payment-tg"
  }
}


resource "aws_lb_target_group" "order_tg" {
  name     = "${local.name_prefix}-order-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check {
    enabled  = true
    path     = "/api/orders/actuator/health"
    protocol = "HTTP"
    port     = "traffic-port"
  }
  tags = {
    Name = "${local.name_prefix}-order-tg"
  }
}
