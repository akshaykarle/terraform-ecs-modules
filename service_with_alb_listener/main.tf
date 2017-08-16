variable "vpc_id" {}
variable "cluster_id" {}
variable "alb_arn" {}
variable "alb_dns_name" {}
variable "alb_zone_id" {}
variable "iam_role_arn" {}
variable "route53_name" {}
variable "route53_zone_id" {}
variable "name" {}
variable "port" {}
variable "health_check_path" { default = "/" }
variable "task_definition" {}

resource "aws_alb_target_group" "default" {
  name       = "${var.name}-${terraform.workspace}"
  tags { env = "${terraform.workspace}" }
  port       = "${var.port}"
  protocol   = "HTTP"
  vpc_id     = "${var.vpc_id}"

  health_check {
    path = "${var.health_check_path}"
  }
}

resource "aws_alb_listener" "default" {
  load_balancer_arn = "${var.alb_arn}"
  port       = "${var.port}"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.default.id}"
    type             = "forward"
  }
}

resource "aws_route53_record" "default" {
  zone_id = "${var.route53_zone_id}"
  name    = "${var.name}.${var.route53_name}"
  type    = "A"

  alias {
    name                   = "${var.alb_dns_name}"
    zone_id                = "${var.alb_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_ecs_service" "service" {
  depends_on = ["aws_alb_listener.default"]
  name            = "${var.name}"
  cluster         = "${var.cluster_id}"
  task_definition = "${var.task_definition}"
  iam_role = "${var.iam_role_arn}"
  desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_alb_target_group.default.arn}"
    container_name   = "${var.name}"
    container_port = "${var.port}"
  }
}

output "service_dns_record" { value = "${aws_route53_record.default.name}" }
