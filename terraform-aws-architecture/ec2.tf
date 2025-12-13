data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  count                  = 3
  ami                    = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
              AZ=$(ec2-metadata --availability-zone | cut -d " " -f 2)

              cat > /var/www/html/index.html <<HTML
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Server $INSTANCE_ID</title>
                  <style>
                      body {
                          font-family: Arial, sans-serif;
                          display: flex;
                          justify-content: center;
                          align-items: center;
                          height: 100vh;
                          margin: 0;
                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                          color: white;
                      }
                      .container {
                          text-align: center;
                          padding: 40px;
                          background: rgba(255, 255, 255, 0.1);
                          border-radius: 20px;
                          backdrop-filter: blur(10px);
                      }
                      h1 { font-size: 3em; margin: 0; }
                      p { font-size: 1.5em; margin: 10px 0; }
                  </style>
              </head>
              <body>
                  <div class="container">
                      <h1>🚀 Server ${count.index + 1}</h1>
                      <p>Instance: $INSTANCE_ID</p>
                      <p>Availability Zone: $AZ</p>
                      <p>Status: <strong>Running</strong></p>
                  </div>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "${var.project_name}-web-${count.index + 1}"
  }
}
