provider "aws" {
  region = "sa-east-1" # Servidor de São Paulo da AWS
  access_key = "" #Autenticação - Informação Sensivel!!!
  secret_key = "" #Autenticação - Informação Sensivel!!!
}

# 1. Criar uma VPC
# 2. Criar uma Internet Gateway
# 3. Criar uma Custom Route Table
# 4. Criar uma Subnet
# 5. Associar a Subnet com a Route Table
# 6. Criar um Grupo de Segurança para permitir as portas 22, 80, 443
# 7. Criar uma Interface de Rede com um IP na Subnet criada na etapa 4
# 8. Atribuir um IP Elástico (publico) para uma Interface de Rede na etapa 7
# 9. Criar um servidor Ubuntu que instala e ativa o Apache2


# 1. Criar uma VPC
resource "aws_vpc" "projeto-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod"
  }
}

# 2. Criar uma Internet Gateway
resource "aws_internet_gateway" "projeto-gw" {
  vpc_id = aws_vpc.projeto-vpc.id

}

# 3. Criar uma Custom Route Table
resource "aws_route_table" "projeto-route-table" {
  vpc_id = aws_vpc.projeto-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.projeto-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.projeto-gw.id
  }

  tags = {
    Name = "prod"
  }
}

# 4. Criar uma Subnet
resource "aws_subnet" "projeto-subnet-1" {
  vpc_id = aws_vpc.projeto-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "projeto-subnet"
  }
}

# 5. Associar a Subnet com a Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.projeto-subnet-1.id
  route_table_id = aws_route_table.projeto-route-table.id
}

# 6. Criar um Grupo de Segurança para permitir as portas 22, 80, 443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web traffic"
  vpc_id      = aws_vpc.projeto-vpc.id

  ingress {
    description = "HTTPS"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Criar uma Interface de Rede com um IP na Subnet criada na etapa 4
resource "aws_network_interface" "web-server-network-interface" {
  subnet_id       = aws_subnet.projeto-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. Atribuir um IP Elástico (publico) para uma Interface de Rede na etapa 7
resource "aws_eip" "eip-public" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-network-interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.projeto-gw]
}

# 9. Criar um servidor Ubuntu que instala e ativa o Apache2
resource "aws_instance" "web-server-instance" {
  ami = "ami-0cdc2f24b2f67ea17"
  instance_type = "t2.micro"
  availability_zone = "sa-east-1a"
  key_name = "Terraform-Projeto"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-network-interface.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo Projeto de servidor Web no AWS > /var/www/html/index.html'
              EOF

  tags = {
    Name = "web-server"
  }
}