
output "public_ip_address" {
  value = azurerm_linux_virtual_machine.vm1_machine.public_ip_address
}
output "public_ip_address_vm2" {
  value = azurerm_linux_virtual_machine.vm2_machine.public_ip_address
}
output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}
