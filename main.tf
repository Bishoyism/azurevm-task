variable "prefix" {
  default = "tfvmex"
}

resource "azurerm_resource_group" "myresource" {
  name     = "my-azure-vm-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "main" {
  name                = "my-azure-vm-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.myresource.location
  resource_group_name = azurerm_resource_group.myresource.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.myresource.name
  virtual_network_name = azurerm_virtual_network.myresource.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "my_public_ip" {
  name                = "publicip"
  resource_group_name = azurerm_resource_group.myresource.name
  location            = azurerm_resource_group.myresource.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "main" {
  depends_on = [
    azurerm_public_ip.my_public_ip
  ]
  name                = "my-azure-vm-nic"
  location            = azurerm_resource_group.myresource.location
  resource_group_name = azurerm_resource_group.myresource.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.my_public_ip.id
  }
}

resource "azurerm_virtual_machine" "main" {
    depends_on = [
      azurerm_network_interface.main
    ]
  name                  = "my-azure-vm"
  location              = azurerm_resource_group.myresource.location
  resource_group_name   = azurerm_resource_group.myresource.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  os_profile_linux_config {
      disable_password_authentication = false
      ssh_keys = [{
        path     = "/home/testadmin/.ssh/authorized_keys"
        key_data = "ssh-rsa -t email@something.com"
      }]
  }
  tags = {
    environment = "staging"
  }
}