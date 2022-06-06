output "resource_group_name" {

  value = azurerm_resource_group.aks.name

}

output "cluster_id" {
  value = module.kubernetes.cluster_id
}

output "kube_config" {
  value     = module.kubernetes.kube_config
  sensitive = true
}

output "kube_admin_config" {
  value     = module.kubernetes.kube_admin_config
  sensitive = true
}


output "vault_uri" {
  value = data.azurerm_key_vault.example.vault_uri
}

