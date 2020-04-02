provider "azurerm" {
    version = 1.38
    }
terraform{
    backend "azurerm"{
        resource_group_name="Terraform"
        storage_account_name="tfstatefileterraform"
        container_name ="tfstatefile"
        key ="terraformvmcreation.tfstate"

    }
}

#Deploy Public IP
resource "azurerm_public_ip" "example2" {
  name                = "pubip2"
  location            = "West US"
  resource_group_name = "TFResourceGroup"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

#Create NIC
resource "azurerm_network_interface" "example2" {
  name                = "Enter name for this NIC"  
  location            = "West US"
  resource_group_name = "TFResourceGroup"

    ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = "/dc47-app-vnet/dc47-app-subnet" 
    private_ip_address_allocation  = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example2.id
  }
}

#Create Boot Diagnostic Account
resource "azurerm_storage_account" "sa" {
  name                     = "azurebootdiagnostictest" 
  resource_group_name      = "TFResourceGroup"
  location                 = "West US"
   account_tier            = "Standard"
   account_replication_type = "LRS"

   tags = {
    environment = "Boot Diagnostic Storage"
    CreatedBy = "Admin"
   }
  }

#Create Virtual Machine
resource "azurerm_virtual_machine" "example" {
  name                  = "drsnap0"  
  location              = "West US"
  resource_group_name   = "TFResourceGroup"
  network_interface_ids = [azurerm_network_interface.example2.id]
  vm_size               = "Standard_B1s"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "osdisk1"
    disk_size_gb      = "128"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "drsnap0"
    admin_username = "vmadmin"
    admin_password = "Password12345!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.sa.primary_blob_endpoint
    }
}