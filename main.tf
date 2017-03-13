provider "aws" {
 region = "us-east-1"
 }
resource "aws_instance" "example" {
ami = "ami-40d28157"
instance_type = "t2.micro"


user_data = <<-EOF
#!/bin/bash
echo "hello world" > index.html
nohup busybox httpd -f -p "${var.server_port}" &
EOF

lifecycle {	
create_before_destroy = true
}
tags {
	Name="terraform-example"
}
}
resource "aws_security_group" "instance" {
name = "terraform-example-instance"
ingress {
from port = "$[var.server_port}"
to port = "${var.server_port}"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
resource "aws_autoscalling_group" "example" {
launch_configuration = "${aws_launch_configuration.example.id}"
availability_zones = ["${data.aws_availability_zones.all.names}"]

load_balancers = ["${aws_elb.example.names}"]
health_check_type = "ELB"

min_size = 2
max_size = 10

tag {
key = "Name"
value = "terraform-asg-example"
propage_at_launch=true
}
resource "aws_elb" "example" {
name = "terraform-asg-example"
availability_zones = ["$data.availability_zones.all.names}"]
security_groups = ["${aws_security_group.elb.id}"]

ingress {
from port = "$[var.server_port}"
to port = "${var.server_port}"
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}
egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
listener {
lb_port = 80
lb_protocol = "http"
instance_port = "${var.server_port}"
instance_protocol = "http"
}
health_check {
healthy_threshold = 2
unhealthy_threshold = 2
timeout = 3
interval = 30
target = "HTTP:${var.server_port}/"
}
lifecycle {
create_before_destroy = true
}
}