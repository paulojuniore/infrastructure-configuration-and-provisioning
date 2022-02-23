# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.91.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "res_group" {
  name     = "rg-win-terraform"
  location = "eastus2"
}

# Create a virtual network
resource "azurerm_virtual_network" "virtual_net" {
  name                = "vn-win-terraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.res_group.location
  resource_group_name = azurerm_resource_group.res_group.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.res_group.name
  virtual_network_name = azurerm_virtual_network.virtual_net.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "public_ip" {
  name = "pi-vm02"
  location = "eastus2"
  resource_group_name = azurerm_resource_group.res_group.name
  allocation_method = "Static"
}

# Create network interface
resource "azurerm_network_interface" "net_interface" {
  name                = "ni_vm02"
  location            = azurerm_resource_group.res_group.location
  resource_group_name = azurerm_resource_group.res_group.name

  ip_configuration {
    name                          = "vm02-niconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# Create a Windows Server virtual machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "windows-vm"
  resource_group_name = azurerm_resource_group.res_group.name
  location            = azurerm_resource_group.res_group.location
  size                = "Standard_F2"
  admin_username      = "pjunior"
  admin_password      = "Pwd12345"
  network_interface_ids = [
    azurerm_network_interface.net_interface.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}