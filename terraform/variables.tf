# terraform/variables.tf

# OpenStack 认证变量
variable "auth_url" {
  description = "OpenStack 认证 URL"
  type        = string
}

variable "tenant_id" {
  description = "OpenStack 项目/租户 ID"
  type        = string
}

variable "tenant_name" {
  description = "OpenStack 项目/租户名称"
  type        = string
}

variable "user_name" {
  description = "OpenStack 用户名"
  type        = string
}

variable "password" {
  description = "OpenStack 密码"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "OpenStack 区域"
  type        = string
  default     = "RegionOne"
}

# 虚拟机配置变量
variable "build_id" {
  description = "Jenkins 构建 ID，用于创建唯一资源名称"
  type        = string
}

variable "app_env" {
  description = "应用环境 (dev/staging/prod)"
  type        = string
  default     = "staging"
}

variable "image_name" {
  description = "OpenStack 镜像名称"
  type        = string
  default     = "ubuntu-22.04"
}

variable "flavor_name" {
  description = "OpenStack 规格名称"
  type        = string
  default     = "m1.small"
}

variable "key_pair_name" {
  description = "OpenStack SSH 密钥对名称"
  type        = string
}

variable "network_name" {
  description = "OpenStack 网络名称"
  type        = string
  default     = "private-network"
}

variable "floating_ip_pool" {
  description = "浮动 IP 池名称"
  type        = string
  default     = "public"
}

# 高级配置
variable "volume_size" {
  description = "数据卷大小 (GB)"
  type        = number
  default     = 20
}

variable "availability_zone" {
  description = "可用区"
  type        = string
  default     = "nova"
}

# 验证规则
variable "instance_count" {
  description = "要创建的实例数量"
  type        = number
  default     = 1
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "实例数量必须在 1 到 10 之间。"
  }
}
