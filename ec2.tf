data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

module "security_group" {
  source                                = "terraform-aws-modules/security-group/aws"
  name                                  = "ec2-ecs-security-group"
  vpc_id                                = var.vpc_id
  ingress_with_source_security_group_id = []
  egress_rules                          = ["all-all"]
}

resource "aws_launch_template" "launchtemplate" {
  name = "template"
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 60
      encrypted             = true
      delete_on_termination = true
    }
  }
  update_default_version = true
  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }
  image_id      = data.aws_ssm_parameter.ami.value
  instance_type = "m6a.4xlarge"
  monitoring {
    enabled = true
  }
  vpc_security_group_ids = [
    module.security_group.security_group_id
  ]
  user_data = base64encode(
    <<EOF
#!/bin/bash
echo "ECS_CLUSTER=clustername" >> /etc/ecs/ecs.config
EOF
  )
}

resource "aws_autoscaling_group" "asg" {
  name                  = "asg"
  desired_capacity      = 0
  max_size              = 1
  min_size              = 0
  protect_from_scale_in = true
  // list of subnet ids to launch the instances in (private subnets)
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.launchtemplate.id
    version = "$Latest"
  }
}