# Configuration Terraform avec vulnérabilités intentionnelles

terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

# Vulnérabilité: Bucket S3 public
resource "aws_s3_bucket" "public_bucket" {
  bucket = "my-public-bucket-test-123"
}

resource "aws_s3_bucket_public_access_block" "public_bucket_pab" {
  bucket = aws_s3_bucket.public_bucket.id

  # Vulnérabilité: Accès public autorisé
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_bucket_policy" {
  bucket = aws_s3_bucket.public_bucket.id

  # Vulnérabilité: Politique permettant l'accès public
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.public_bucket.arn}/*"
      }
    ]
  })
}

# Vulnérabilité: Instance EC2 sans paire de clés
resource "aws_instance" "vulnerable_instance" {
  ami           = "ami-0c02fb55956c7d316"
  instance_type = "t2.micro"

  # Vulnérabilité: Pas de paire de clés
  # key_name = "my-key-pair"

  # Vulnérabilité: Groupe de sécurité ouvert
  vpc_security_group_ids = [aws_security_group.open_sg.id]

  # Vulnérabilité: Pas de chiffrement du volume root
  root_block_device {
    volume_type = "gp2"
    volume_size = 20
    encrypted   = false
  }

  tags = {
    Name = "VulnerableInstance"
  }
}

# Vulnérabilité: Groupe de sécurité trop permissif
resource "aws_security_group" "open_sg" {
  name_prefix = "open-sg"
  description = "Security group with open access"

  # Vulnérabilité: SSH ouvert à tous
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vulnérabilité: HTTP ouvert à tous
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Vulnérabilité: Tous les ports sortants ouverts
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "OpenSecurityGroup"
  }
}

# Vulnérabilité: Base de données RDS sans chiffrement
resource "aws_db_instance" "vulnerable_db" {
  identifier = "vulnerable-db"
  
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  
  allocated_storage = 20
  storage_type      = "gp2"
  
  # Vulnérabilité: Pas de chiffrement
  storage_encrypted = false
  
  db_name  = "testdb"
  username = "admin"
  password = "password123"  # Vulnérabilité: Mot de passe en dur
  
  # Vulnérabilité: Accessible publiquement
  publicly_accessible = true
  
  # Vulnérabilité: Pas de sauvegarde
  backup_retention_period = 0
  
  # Vulnérabilité: Pas de logs d'audit
  enabled_cloudwatch_logs_exports = []
  
  skip_final_snapshot = true
  
  tags = {
    Name = "VulnerableDatabase"
  }
}