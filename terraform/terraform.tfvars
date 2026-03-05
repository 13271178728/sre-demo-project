# terraform/terraform.tfvars.example
# 复制这个文件为 terraform.tfvars 并填入实际值

# OpenStack 认证信息（请替换为实际值）
auth_url      = "http://10.1.1.180:5000/v3"
tenant_id     = "7996410a400c42559988c96f33738d51"
tenant_name   = "admin"
user_name     = "admin"
password      = "jiaxun@123"
region        = "RegionOne"

# 虚拟机配置
image_name    = "ceos-arrch"
flavor_name   = "8C16G200G"
key_pair_name = "sre-demo-key"
network_name  = "network2"
#floating_ip_pool = "public"

# 环境设置
app_env       = "staging"
build_id      = "local-test"  # Jenkins 会自动覆盖这个值
