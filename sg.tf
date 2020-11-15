resource "exoscale_security_group" "sg" {
  name = "sprint_one"
}
resource "exoscale_security_group_rule" "http" {
  security_group_id = exoscale_security_group.sg.id
  type = "INGRESS"
  protocol = "tcp"
  cidr = "0.0.0.0/0"
  start_port = 80
  end_port = 80
}
resource "exoscale_security_group_rule" "prometheus_one" {
  security_group_id = exoscale_security_group.sg.id
  type = "INGRESS"
  protocol = "tcp"
  cidr = "0.0.0.0/0"
  start_port = 9100
  end_port = 9100
}

resource "exoscale_security_group_rule" "prometheus_two" {
  security_group_id = exoscale_security_group.sg.id
  type = "INGRESS"
  protocol = "tcp"
  cidr = "0.0.0.0/0"
  start_port = 9090
  end_port = 9090
}