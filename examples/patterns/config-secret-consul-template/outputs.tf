output "vault_fake_service_token" {
  description = "Vault service-a token"
  value       = module.vault.service-a_token
  sensitive   = true
}