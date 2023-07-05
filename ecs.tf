resource "aws_ecs_capacity_provider" "cp" {
  name = "EC2"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_ecs_cluster" "ecs" {
  depends_on = [
    aws_ecs_capacity_provider.cp
  ]
  name = "clustername"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "providers" {
  cluster_name = aws_ecs_cluster.ecs.name
  capacity_providers = [
    "FARGATE", "FARGATE_SPOT", "EC2"
  ]
}