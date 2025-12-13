# AWS Architecture with Terraform

Arquitectura de AWS con 3 instancias EC2, Application Load Balancer y Route 53.

## Arquitectura

```
Route 53 (DNS)
    ↓
Application Load Balancer
    ↓
┌───────┼───────┐
↓       ↓       ↓
EC2-1  EC2-2  EC2-3
(us-east-1a) (us-east-1b) (us-east-1c)
```

## Recursos Creados

- **VPC** con 3 subnets públicas en diferentes Availability Zones
- **3 instancias EC2** con Apache instalado y página HTML personalizada
- **Application Load Balancer** con health checks configurados
- **Target Group** con las 3 instancias registradas
- **Security Groups** para ALB y EC2 instances
- **Route 53** record apuntando al ALB (opcional)

## Prerequisitos

1. Terraform instalado (>= 1.0)
2. AWS CLI configurado con credenciales
3. Par de llaves SSH en AWS (opcional para acceso SSH)
4. Dominio registrado en Route 53 (opcional)

## Configuración

### 1. Crear archivo de variables

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 2. Editar terraform.tfvars

```hcl
aws_region   = "us-east-1"
project_name = "my-app"

instance_type = "t3.micro"
key_name      = "mi-llave-ssh"  # Opcional

# Configuración de dominio
domain_name          = "example.com"
subdomain            = "www"
create_route53_zone  = false              # true si quieres crear una nueva zona
route53_zone_id      = "Z1234567890ABC"   # Si usas una zona existente
```

### 3. Obtener Zone ID de Route 53 (si usas dominio existente)

```bash
aws route53 list-hosted-zones
```

Copia el ID de tu zona (sin el prefijo `/hostedzone/`).

## Despliegue

### 1. Inicializar Terraform

```bash
cd terraform-aws-architecture
terraform init
```

### 2. Revisar el plan

```bash
terraform plan
```

### 3. Aplicar la configuración

```bash
terraform apply
```

Escribe `yes` cuando te pida confirmación.

### 4. Ver outputs

```bash
terraform output
```

Verás información como:
- URLs de las instancias EC2
- DNS del Load Balancer
- URL de tu aplicación
- Name servers de Route 53 (si creaste una zona nueva)

## Acceder a la aplicación

### Opción 1: Usar el DNS del ALB

```bash
# Obtener el DNS del ALB
terraform output alb_url

# Visitar en el navegador
http://my-app-alb-123456789.us-east-1.elb.amazonaws.com
```

### Opción 2: Usar tu dominio (después de configurar DNS)

Si creaste una zona nueva, configura los name servers en tu registrador de dominios:

```bash
terraform output route53_name_servers
```

Luego visita:
```
http://www.example.com
```

## Verificar que funciona

Cada vez que recargues la página, verás una pantalla diferente mostrando:
- Número del servidor (1, 2, o 3)
- Instance ID
- Availability Zone

Esto demuestra que el Load Balancer está distribuyendo el tráfico entre las 3 instancias.

## Acceder a las instancias EC2 por SSH

```bash
# Obtener las IPs públicas
terraform output ec2_public_ips

# Conectar a una instancia
ssh -i ~/.ssh/mi-llave-ssh.pem ec2-user@<IP_PUBLICA>
```

## Costos Estimados

Costos aproximados en us-east-1:

- **EC2 t3.micro**: $0.0104/hora × 3 = $0.0312/hora (~$22.46/mes)
- **Application Load Balancer**: $0.0225/hora + $0.008/LCU-hora (~$16.20/mes base)
- **Route 53 Hosted Zone**: $0.50/mes
- **Data Transfer**: Variable según tráfico

**Total estimado**: ~$40-50/mes para uso básico

## Personalización

### Cambiar el HTML de las instancias

Edita el `user_data` en `ec2.tf`:

```hcl
user_data = <<-EOF
  #!/bin/bash
  # Tu script personalizado aquí
EOF
```

### Agregar HTTPS

1. Obtén un certificado SSL en AWS Certificate Manager
2. Agrega un listener HTTPS en `alb.tf`:

```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:..."

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
```

### Cambiar el tipo de instancia

En `terraform.tfvars`:

```hcl
instance_type = "t3.small"  # o t3.medium, t3.large, etc.
```

## Troubleshooting

### Las instancias no aparecen como healthy

```bash
# Ver el estado del target group
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw target_group_arn)
```

Verifica que:
- Las instancias estén corriendo
- Apache esté activo: `systemctl status httpd`
- El security group permita tráfico del ALB

### No puedo acceder por SSH

Verifica que:
- La key pair esté configurada correctamente
- Tu IP esté permitida en el security group (actualmente permite 0.0.0.0/0)
- Las instancias tengan IPs públicas

### La página no carga

```bash
# Probar acceso directo a una instancia
curl http://<EC2_PUBLIC_IP>

# Probar el ALB
curl $(terraform output -raw alb_url)
```

## Limpieza

Para eliminar todos los recursos:

```bash
terraform destroy
```

Escribe `yes` para confirmar.

**IMPORTANTE**: Esto eliminará todos los recursos y no se puede deshacer.

## Estructura de archivos

```
terraform-aws-architecture/
├── main.tf                    # VPC, subnets, security groups
├── ec2.tf                     # Instancias EC2
├── alb.tf                     # Application Load Balancer
├── route53.tf                 # Route 53 DNS
├── variables.tf               # Declaración de variables
├── outputs.tf                 # Outputs
├── terraform.tfvars.example   # Ejemplo de configuración
└── README.md                  # Este archivo
```

## Próximos pasos

- Agregar Auto Scaling Group para escalado automático
- Configurar HTTPS con Certificate Manager
- Implementar RDS para base de datos
- Agregar CloudWatch alarms para monitoreo
- Configurar backups automatizados
- Implementar WAF para seguridad adicional

## Recursos adicionales

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Route 53 Documentation](https://docs.aws.amazon.com/route53/)
