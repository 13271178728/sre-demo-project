# 虚拟机信息
output "instance_id" {
  description = "创建的虚拟机 ID"
  value       = openstack_compute_instance_v2.sre_vm.id
}

output "instance_name" {
  description = "创建的虚拟机名称"
  value       = openstack_compute_instance_v2.sre_vm.name
}

output "instance_ip" {
  description = "虚拟机的私有 IP 地址"
  value       = openstack_compute_instance_v2.sre_vm.access_ip_v4
}

# 安全组信息
output "security_group_id" {
  description = "创建的安全组 ID"
  value       = openstack_compute_secgroup_v2.sre_secgroup.id
}

output "security_group_name" {
  description = "创建的安全组名称"
  value       = openstack_compute_secgroup_v2.sre_secgroup.name
}

# 构建信息
output "build_info" {
  description = "构建信息"
  value = {
    build_id     = var.build_id
    environment  = var.app_env
    created_at   = timestamp()
    region       = var.region
    image_name   = var.image_name
    flavor_name  = var.flavor_name
  }
}

# SSH 连接信息（通过私有 IP）
output "ssh_command" {
  description = "SSH 连接命令（需要通过 VPN 或跳板机）"
  value       = "ssh -i ${var.key_pair_name}.pem ubuntu@${openstack_compute_instance_v2.sre_vm.access_ip_v4}"
}

# 内部访问地址
output "internal_health_check" {
  description = "内部健康检查地址"
  value       = "http://${openstack_compute_instance_v2.sre_vm.access_ip_v4}/health"
}

# 节点监控地址
output "internal_node_exporter" {
  description = "内部 Node Exporter 地址"
  value       = "http://${openstack_compute_instance_v2.sre_vm.access_ip_v4}:9100/metrics"
}
