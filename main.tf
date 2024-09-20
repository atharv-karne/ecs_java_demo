provider "aws" {
  region = "ap-south-1"
}

# Create Security Group
resource "aws_security_group" "allow_all" {
  vpc_id = "vpc-0f2fe70ca733aa854"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create IAM Role for ECS Instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "customecsInstanceRoleChanged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Policies to ECS Instance Role
resource "aws_iam_policy_attachment" "ecs_instance_role_policy" {
  name       = "ecs_instance_role_policy_Changed"
  roles      = [aws_iam_role.ecs_instance_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Create IAM Role for ECS Tasks
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRoleChanged"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Policies to ECS Task Role
resource "aws_iam_policy_attachment" "ecs_task_role_policy" {
  name       = "ecs_task_role_policy_Changed"
  roles      = [aws_iam_role.ecs_task_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create IAM Instance Profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfileChanged14"
  role = aws_iam_role.ecs_instance_role.name
}

# Create Launch Configuration
resource "aws_launch_configuration" "lc" {
  image_id             = "ami-045162d33517975f5"  
  instance_type        = "t2.medium"
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups      = [aws_security_group.allow_all.id]
  user_data            = <<-EOF
        #!/bin/bash
        echo "Starting user data script" >> /var/log/ecs-user-data.log

        # Update the system
        sudo yum update -y

        # # Install the ECS agent
        # sudo amazon-linux-extras enable ecs
        # sudo yum install -y ecs-init

        # Configure the ECS agent
        echo "ECS_CLUSTER=${aws_ecs_cluster.main_cluster.name}" | sudo tee /etc/ecs/ecs.config

        # Start ECS agent

        sudo systemctl enable --now --no-block ecs
        sudo systemctl stop ecs
        sudo systemctl start ecs


        echo "User data script completed successfully" >> /var/log/ecs-user-data.log

              EOF
  root_block_device {
    volume_size = 24
  }
}



# Create Target Group
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = "vpc-0f2fe70ca733aa854"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 3
    unhealthy_threshold  = 3
  }
}

# Create Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            = ["subnet-06e2a9084baca9d48", "subnet-04a80ca11363a735d"]
  enable_deletion_protection = false
}

# Create ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 8081
  protocol          = "HTTP"
  
  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service is running"
      status_code  = "200"
    }
  }
}

# Create Listener Rule to forward traffic to Target Group
resource "aws_lb_listener_rule" "app_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  condition {
    # field  = "path-pattern"
    path_pattern {
      values = ["/*"]
    }
  }
}

# Create Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.lc.id
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier  = ["subnet-06e2a9084baca9d48", "subnet-04a80ca11363a735d"]

  # Attach the Target Group
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  # Health check type should be ELB
  health_check_type          = "ELB"
  health_check_grace_period = 300
}

# Create ECS Cluster
resource "aws_ecs_cluster" "main_cluster" {
  name = "ecs-cluster"
}

# Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/my-java-app-changed"
}

# Create ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-java-app"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name      = "java-app"
    image     = "730335267178.dkr.ecr.ap-south-1.amazonaws.com/my-spring-boot-app:latest"
    memory    = 512
    cpu       = 256
    essential = true
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
    }]
    entryPoint = ["/bin/sh", "-c"]
    command    = [
      "echo 'Starting application'; java -jar /app.jar"
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/my-java-app-changed"
        "awslogs-region"        = "ap-south-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}


# Create ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "java-app-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "EC2"
  
  # Ensure that the service uses the ALB for load balancing
  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "java-app"
    container_port   = 8081
  }
}




#Here i wanna try if this commit makes pipeline trigger