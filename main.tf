# ami-0dcf20045412efa41

provider "aws" {
  region = "ap-south-1"
}

# Create VPC
resource "aws_vpc" "ecs_vpc_main" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.ecs_vpc_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
}

# Create Security Group
resource "aws_security_group" "allow_all" {
  vpc_id = aws_vpc.ecs_vpc_main.id

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

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc_main.id

  tags = {
    Name = "ecs-igw-1"
  }
}

# Create Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_vpc_main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table-changed"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_subnet" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.public.id
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
  name = "ecsInstanceProfileChanged3"
  role = aws_iam_role.ecs_instance_role.name
}

# Create Launch Configuration
resource "aws_launch_configuration" "lc" {
  image_id             = "ami-0dcf20045412efa41"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs_instance_profile.name
  security_groups      = [aws_security_group.allow_all.id]
  user_data            = <<-EOF
              #!/bin/bash
              
              # Update the system
              sudo yum update -y

              # Install the ECS agent
              sudo curl -o /etc/yum.repos.d/ecs.repo https://amazon-ecs-agent.s3.amazonaws.com/amazon-ecs-agent.repo
              sudo yum install -y ecs-init
              
              # Configure the ECS agent
              echo "ECS_CLUSTER=${aws_ecs_cluster.main_cluster.name}" | sudo tee /etc/ecs/ecs.config
              
              # Start and enable the ECS agent
              sudo systemctl stop ecs
              sudo systemctl start ecs
              sudo systemctl enable ecs

              # Install Maven
              sudo wget http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo -O /etc/yum.repos.d/epel-apache-maven.repo
              sudo sed -i s/\$releasever/6/g /etc/yum.repos.d/epel-apache-maven.repo
              sudo yum install -y apache-maven
              EOF
  root_block_device {
    volume_size = 24
  }
}



# Create Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  launch_configuration = aws_launch_configuration.lc.id
  min_size             = 1
  max_size             = 2
  vpc_zone_identifier  = [aws_subnet.main.id]


}


# Create ECS Cluster
resource "aws_ecs_cluster" "main_cluster" {
  name = "ecs-cluster"
}


#Log group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/my-java-app-changed"
}


# Create ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-java-app"
  requires_compatibilities = ["EC2"]
  # cpu =256
  # memory=512
  network_mode             = "bridge"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name      = "java-app"
    image     = "https://730335267178.dkr.ecr.ap-south-1.amazonaws.com/my-spring-boot-app:latest"
    memory    = 512
    cpu       = 256
    essential = true
    portMappings = [{
      containerPort = 8081
      hostPort      = 8081
    }]

     logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/my-java-app"
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
}
