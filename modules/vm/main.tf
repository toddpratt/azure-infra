variable "name" {
  description = "Base name for the VM and related resources"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to attach the NIC"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key path or value"
  type        = string
}

variable "vm_size" {
  description = "VM size"
  type        = string
  default     = "Standard_B1ls"
}

variable "create_public_ip" {
  description = "Whether to create a public IP for the VM"
  type        = bool
  default     = false
}

# Optional public IP
resource "azurerm_public_ip" "this" {
  count               = var.create_public_ip ? 1 : 0
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

# NIC
resource "azurerm_network_interface" "this" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.create_public_ip ? azurerm_public_ip.this[0].id : null
  }
}

# VM
resource "azurerm_linux_virtual_machine" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.this.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "${var.name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

output "jump_private_ip" {
  value = azurerm_network_interface.this.private_ip_address
}

output "jump_public_ip" {
  value = var.create_public_ip ? azurerm_public_ip.this[0].id : null
}

