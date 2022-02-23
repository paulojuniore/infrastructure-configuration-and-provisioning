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
  name = "rg-terraform"
  location = "eastus2"
}

# Create a virtual network
resource "azurerm_virtual_network" "virtual_net" {
  name = "vn-terraform"
  address_space = ["10.1.0.0/16"]
  location = "eastus2"
  resource_group_name = azurerm_resource_group.res_group.name
}

# Create a subnet
resource "azurerm_subnet" "subnet" {
  name = "internal"
  resource_group_name = azurerm_resource_group.res_group.name
  virtual_network_name = azurerm_virtual_network.virtual_net.name
  address_prefixes = ["10.1.1.0/24"]
}

# Create public IP
resource "azurerm_public_ip" "public_ip" {
  name = "pi-vm01"
  location = "eastus2"
  resource_group_name = azurerm_resource_group.res_group.name
  allocation_method = "Static"
}

# Create network interface
resource "azurerm_network_interface" "net_interface" {
  name = "ni_vm01"
  location = "eastus2"
  resource_group_name = azurerm_resource_group.res_group.name
  ip_configuration {
    name = "vm01-niconfig"
    subnet_id = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

# Create a Linux virtual machine
resource "azurerm_virtual_machine" "vm" {
  name = "vm01"
  location = "eastus2"
  resource_group_name = azurerm_resource_group.res_group.name
  network_interface_ids = [azurerm_network_interface.net_interface.id]
  vm_size = "Standard_DS1_v2"

  storage_os_disk {
    name = "vm01-osdisk"
    caching = "ReadWrite"
    create_option = "fromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04.0-LTS"
    version = "latest"
  }

  os_profile {
    computer_name = "vm01"
    admin_username = "pjunior"
    admin_password = "Pwd1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  connection {
    host = "sometestdn.ukwest.cloudapp.azure.com"
    user = "pjunior"
    type = "ssh"
    password = "Pwd1234"
  }
}

# connects the newly created virtual machine and does apt-get update, 
## apache installation, firewall tweaks to allow access to apache and
### start apache service.
resource "azurerm_virtual_machine_extension" "terraformvm" {
  name                 = "vm01"
  virtual_machine_id = azurerm_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "commandToExecute": "apt-get update -y && apt-get install apache2 -y && ufw app list && ufw allow 'Apache Full' && ufw status && systemctl status apache2"
    }
  SETTINGS
}
