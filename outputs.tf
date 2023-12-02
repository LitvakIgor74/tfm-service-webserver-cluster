output "lb_dns_name" {
  description = <<-EOS
                Represents the dns name of load balancer.
                EOS
  value = aws_lb.alb.dns_name
}

output "asg_name" {
  description = <<-EOS
                Represents the name of autoscaling group.
                EOS
  value = aws_autoscaling_group.all_http_traffic.name
}