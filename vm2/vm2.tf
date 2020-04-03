provider "azurerm" {
    version = 1.38
    }

terraform{
    backend "azurerm"{
        resource_group_name="Terraform"
        storage_account_name="vedaantisninjaboot"
        container_name ="tfstatefile"
        key ="terraformvm2creation.tfstate"

    }
}
# Create virtual network
resource "azurerm_virtual_network" "TFNet" {
    name                = "TFVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "West US2"
    resource_group_name = "TFResourceGroup"

    tags = {
        environment = "Terraform VNET"
    }
}
# Create subnet
resource "azurerm_subnet" "tfsubnet" {
    name                 = "default"
    resource_group_name = "TFResourceGroup"
    virtual_network_name = azurerm_virtual_network.TFNet.name
    address_prefix       = "10.0.1.0/24"
}

#Deploy Public IP

resource "azurerm_public_ip" "pubip3" {
  name                = "pubip3"
  location            = "West US2"
  resource_group_name = "TFResourceGroup"
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}
#Create NIC

resource "azurerm_network_interface" "drsnap1-nic" {
  name                = "drnsap1-nic"  
  location            = "West US2"
  resource_group_name = "TFResourceGroup"

    ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.tfsubnet.id 
    private_ip_address_allocation  = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip3.id
  }
}


#Create Boot Diagnostic Account
resource "azurerm_storage_account" "sa" {
  name                     = "azurebootdiagnostictest2" 
  resource_group_name      = "TFResourceGroup"
  location                 = "West US2"
   account_tier            = "Standard"
   account_replication_type = "LRS"

   tags = {
    environment = "Boot Diagnostic Storage"
    CreatedBy = "Admin"
   }
  }

#Create Virtual Machine

resource "azurerm_virtual_machine" "drsnap1" {
  name                  = "drsnap1"  
  location              = "West US2"
  resource_group_name   = "TFResourceGroup"
  network_interface_ids = [azurerm_network_interface.drsnap1-nic.id]
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
    name              = "osdisk2"
    disk_size_gb      = "40"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "drsnap1"
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