# terraform/main.tf
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    openstack = {
      source = "registry.terraform.io/terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
  }
}

# 配置 OpenStack Provider
provider "openstack" {
  # 认证信息将通过环境变量传入
  # 不需要在这里硬编码任何凭证
  auth_url    = var.auth_url
  tenant_id   = var.tenant_id
  tenant_name = var.tenant_name
  user_name   = var.user_name
  password    = var.password
  region      = var.region
  cacert_file = "/etc/pki/ca-trust/source/anchors/root.crt"
}

# 创建安全组
resource "openstack_compute_secgroup_v2" "sre_secgroup" {
  name        = "sre-demo-sg-${var.build_id}"
  description = "Security group for SRE demo VM"

  # SSH 访问
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # HTTP 访问
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # HTTPS 访问
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  # ICMP (ping)
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }

  # 应用监控端口
  rule {
    from_port   = 9100
    to_port     = 9100
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

# 创建浮动 IP
#resource "openstack_networking_floatingip_v2" "sre_fip" {
#  pool = var.floating_ip_pool
#}

# 创建虚拟机和端口
resource "openstack_compute_instance_v2" "sre_vm" {
  name        = "sre-demo-${var.build_id}"
  image_name  = var.image_name
  flavor_name = var.flavor_name
  key_pair    = var.key_pair_name
  security_groups = [openstack_compute_secgroup_v2.sre_secgroup.name]

  network {
    name = var.network_name
  }

  # 用户数据脚本（cloud-init）
  user_data = <<-EOF
    #!/bin/bash
    # SRE Demo VM 初始化脚本
    set -e  # 遇到错误立即退出

    echo "[$(date)] 开始初始化 SRE Demo 虚拟机" > /var/log/sre-init.log
    
    # 更新系统包
    apt-get update -y
    apt-get upgrade -y
    
    # 安装基本工具
    apt-get install -y \
        curl \
        wget \
        vim \
        htop \
        net-tools \
        tree \
        git \
        python3-pip \
        python3-venv \
        prometheus-node-exporter \
        docker.io \
        docker-compose
    
    # 启动 Docker
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu
    
    # 创建应用目录
    mkdir -p /opt/sre-demo/{app,logs,config,scripts}
    mkdir -p /data/{prometheus,grafana}
    
    # 设置应用环境变量
    echo "export APP_ENV=${var.app_env}" >> /etc/profile.d/sre-demo.sh
    echo "export BUILD_ID=${var.build_id}" >> /etc/profile.d/sre-demo.sh
    echo "export DEPLOY_TIME=$(date)" >> /etc/profile.d/sre-demo.sh
    
    # 创建简单的健康检查脚本
    cat > /opt/sre-demo/scripts/healthcheck.sh <<'SCRIPT'
#!/bin/bash
# 简单的健康检查脚本
echo "{
  \"status\": \"healthy\",
  \"hostname\": \"$(hostname)\",
  \"ip\": \"$(hostname -I | awk '{print $1}')\",
  \"timestamp\": \"$(date -Iseconds)\",
  \"services\": {
    \"docker\": \"$(systemctl is-active docker)\",
    \"node_exporter\": \"$(systemctl is-active prometheus-node-exporter)\"
  },
  \"disk_usage\": \"$(df -h / | awk 'NR==2 {print $5}')\",
  \"memory_usage\": \"$(free -h | awk 'NR==2 {print $3"/"$2}')\",
  \"uptime\": \"$(uptime)\"
}" > /opt/sre-demo/logs/health.json
cat /opt/sre-demo/logs/health.json
SCRIPT
    
    chmod +x /opt/sre-demo/scripts/healthcheck.sh
    
    # 创建欢迎文件
    echo "Welcome to SRE Demo VM" > /tmp/welcome.txt
    echo "Build ID: ${var.build_id}" >> /tmp/welcome.txt
    echo "Created at: $(date)" >> /tmp/welcome.txt
    echo "OpenStack Region: ${var.region}" >> /tmp/welcome.txt
    echo "----------------------------------------" >> /tmp/welcome.txt
    echo "可用命令:" >> /tmp/welcome.txt
    echo "  - 查看健康状态: /opt/sre-demo/scripts/healthcheck.sh" >> /tmp/welcome.txt
    echo "  - 查看日志: tail -f /var/log/sre-init.log" >> /tmp/welcome.txt
    echo "  - Docker 状态: docker ps" >> /tmp/welcome.txt
    
    # 设置定时任务（每5分钟收集一次健康状态）
    echo "*/5 * * * * root /opt/sre-demo/scripts/healthcheck.sh" >> /etc/crontab
    
    # 配置系统参数
    echo "net.core.somaxconn = 65535" >> /etc/sysctl.conf
    echo "vm.swappiness = 10" >> /etc/sysctl.conf
    sysctl -p
    
    # 启动 node exporter
    systemctl enable prometheus-node-exporter
    systemctl start prometheus-node-exporter
    
    echo "[$(date)] 初始化完成" >> /var/log/sre-init.log
    
    # 输出 VM 信息到控制台（可以在 OpenStack 控制台日志中看到）
    echo "=========================================="
    echo "SRE Demo VM 初始化成功"
    echo "Hostname: $(hostname)"
    echo "IP: $(hostname -I)"
    echo "Build ID: ${var.build_id}"
    echo "=========================================="
  EOF

  # 添加标签
  tags = [
    "sre-demo",
    "environment-${var.app_env}",
    "build-${var.build_id}",
    "created-${formatdate("YYYY-MM-DD", timestamp())}"
  ]

  # 挂载数据卷（可选）
  # block_device {
  #   uuid                  = var.volume_id
  #   source_type           = "volume"
  #   destination_type      = "volume"
  #   boot_index            = 1
  #   delete_on_termination = true
  # }
}

# 关联浮动 IP 到虚拟机
#resource "openstack_compute_floatingip_associate_v2" "sre_fip_assoc" {
#  floating_ip = openstack_networking_floatingip_v2.sre_fip.address
#  instance_id = openstack_compute_instance_v2.sre_vm.id
#}
