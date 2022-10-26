resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

data "azurerm_resource_group" "rg" {
  name = "OPS345"
}

variable "resource_location" {
  default = "West US 3"
}

locals {
  prefix = "OPS345"
}


# Create virtual network
resource "azurerm_virtual_network" "my_terraform_network" {
  #  name          = "OPS345-vnet-tf"
  #  location            = "West US 3"
  name                = "${local.prefix}-vnet-tf"
  address_space       = ["10.0.0.0/16", "192.168.0.0/24"]
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name
}

# DUPLICATED NEED LOOPING LOGIC

# Create subnet
resource "azurerm_subnet" "vm1_subnet" {
  name                 = "${local.prefix}-10.0.0.0"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "vm2_subnet" {
  name                 = "${local.prefix}-192.168.0.0"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["192.168.0.0/24"]
}

# DUPLICATED NEED LOOPING LOGIC

# Create public IPs
resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "${local.prefix}-vm1-ip"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create public IPs
resource "azurerm_public_ip" "vm2_public_ip" {
  name                = "${local.prefix}-vm2-ip"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm_security_group" {
  name                = "${local.prefix}-nwk-sec-group"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# DUPLICATED NEED LOOPING LOGIC

# Create network interface
resource "azurerm_network_interface" "vm1_nic_10" {
  name                = "${local.prefix}-vm1-nic_10"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.prefix}-10-vm1-10-conf"
    subnet_id                     = azurerm_subnet.vm1_subnet.id
    public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }

}

# Create network interface
resource "azurerm_network_interface" "vm1_nic_192" {
  name                = "${local.prefix}-vm1-nic_192"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.prefix}-vm1-192-conf"
    subnet_id                     = azurerm_subnet.vm2_subnet.id
    private_ip_address            = "192.168.0.10"
    private_ip_address_allocation = "Static"
  }

}

# Create network interface
resource "azurerm_network_interface" "vm2_nic_10" {
  name                = "${local.prefix}-vm2-nic_10"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.prefix}-vm2-10-conf"
    subnet_id                     = azurerm_subnet.vm1_subnet.id
    public_ip_address_id          = azurerm_public_ip.vm2_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_network_interface" "vm2_nic_192" {
  name                = "${local.prefix}-vm2-nic_192"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${local.prefix}-vm2-192-conf"
    subnet_id                     = azurerm_subnet.vm2_subnet.id
    private_ip_address            = "192.168.0.20"
    private_ip_address_allocation = "Static"
  }


}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "vm1_nic_sg_association" {
  network_interface_id      = azurerm_network_interface.vm1_nic_10.id
  network_security_group_id = azurerm_network_security_group.vm_security_group.id
}

resource "azurerm_network_interface_security_group_association" "vm2_nic_sg_association" {
  network_interface_id      = azurerm_network_interface.vm2_nic_10.id
  network_security_group_id = azurerm_network_security_group.vm_security_group.id
}


# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm1_machine" {
  name                  = "${local.prefix}-vm1"
  location              = var.resource_location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm1_nic_10.id, azurerm_network_interface.vm1_nic_192.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "${local.prefix}-vm1-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  computer_name                   = "${local.prefix}-vm1"
  admin_username                  = "ops345"
  disable_password_authentication = false

  admin_password = "Password1234"


  source_image_reference {
    publisher = var.linux_vm_image_publisher
    offer     = var.linux_vm_image_offer
    sku       = var.centos_7_gen2_sku
    version   = "latest"

  }
}

resource "azurerm_linux_virtual_machine" "vm2_machine" {
  name                  = "${local.prefix}-vm2"
  location              = var.resource_location
  resource_group_name   = data.azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm2_nic_10.id, azurerm_network_interface.vm2_nic_192.id]
  size                  = "Standard_B1ls"

  os_disk {
    name                 = "${local.prefix}-vm2-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  # procomputers:centos-7-9:centos-7-9:7.9.20201116


  computer_name                   = "${local.prefix}-vm2"
  admin_username                  = "ops345"
  disable_password_authentication = false

  admin_password = "Password1234"

  source_image_reference {
    publisher = var.linux_vm_image_publisher
    offer     = var.linux_vm_image_offer
    sku       = var.centos_7_gen2_sku
    version   = "latest"

  }
#  source_image_reference {
#    publisher = "procomputers"
#    offer     = "centos-7-9"
#    sku       = "centos-7-9"
#    version   = "7.9.20220302"
#
#  }
#  plan {
#    name      = "centos-7-9"
#    product   = "centos-7-9"
#    publisher = "procomputers"
#  }


  #  boot_diagnostics {
  #    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  #  }
}


#resource "azurerm_resource_group" "rg" {
#  location = var.resource_group_location
#  name     = random_pet.rg_name.id
#}

# Create storage account for boot diagnostics
#resource "azurerm_storage_account" "my_storage_account" {
#  name                     = "diag${random_id.random_id.hex}"
#  location                 = var.resource_location
#  resource_group_name      = data.azurerm_resource_group.rg.name
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#}


#resource "azurerm_network_security_rule" "inboundVnet" {
#  name                        = "AllowVnetInBound"
#  priority                    = 10002
#  direction                   = "Inbound"
#  access                      = "Allow"
#  protocol                    = "Tcp"
#  source_port_range           = "*"
#  destination_port_range      = "*"
#  source_address_prefix       = "*"
#  destination_address_prefix  = "*"
#  resource_group_name         = azurerm_resource_group.example.name
#  network_security_group_name = azurerm_network_security_group.example.name
#}