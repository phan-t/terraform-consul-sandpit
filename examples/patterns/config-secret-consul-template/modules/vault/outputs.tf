output "service-a_token" {
  description = "service-a token"
  value       = vault_token.service-a.client_token
}