provider "azurerm" {
  version = "=2.3.0"
  features {}
}

terraform{
  backend "azurerm" {
    resource_group_name = "tstate-rg"
    storage_account_name =  "tstate123sa"
    container_name = "sides"
    key            = "sides.tfstate"
    access_key  = "lL98ruzb12F+0wuy6L2J8wDRqbhjzrOalMxwUbVS6Fc5LHsnNBLpXdWNt8SbUepaZP0CFpPdTVgiRFENDRXFkQ=="
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


# Create network security group and SSH rule for subnet.
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_network_security_rule" "allow-ssh" {
  name                       = "allow-ssh"
  priority                   = 101
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_security_rule" "allow-http-8080" {
  name                       = "allow-http-8080"
  priority                   = 200
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet" "sbnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     =  "10.0.2.0/27"
}

# Associate network security group with subnet.
resource "azurerm_subnet_network_security_group_association" "subnet_assoc" {
  subnet_id                 =  azurerm_subnet.sbnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# # Create a public IP address for db server VM in public subnet.
# resource "azurerm_public_ip" "db_public_ip" {
#     name                         = "${var.prefix}-db_public_ip"
#     resource_group_name          = azurerm_resource_group.rg.name
#     location                     = azurerm_resource_group.rg.location
#     allocation_method            = "Dynamic"
# }
# Create a public IP address for web server VM in public subnet.
resource "azurerm_public_ip" "web_public_ip" {
    name                         = "${var.prefix}-web_public_ip"
    resource_group_name          = azurerm_resource_group.rg.name
    location                     = azurerm_resource_group.rg.location
    allocation_method            = "Dynamic"
}

# resource "azurerm_network_interface" "db-nic" {
#   name                = "${var.prefix}-db-nic"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location

#   ip_configuration {
#     name                          = "internal"
#     subnet_id                     = azurerm_subnet.sbnet.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.db_public_ip.id

#   }
# }

resource "azurerm_network_interface" "web-nic" {
  name                = "${var.prefix}-web-nic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sbnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id

  }
}

# resource "azurerm_linux_virtual_machine" "db-vm" {
#   name                            = "${var.prefix}-db-vm"
#   resource_group_name             = azurerm_resource_group.rg.name
#   location                        = azurerm_resource_group.rg.location
#   size                            = "Standard_F2"
#   admin_username                  = "azureuser"
#   network_interface_ids = [
#     azurerm_network_interface.db-nic.id,
#   ]

#   admin_ssh_key {
#     username = "azureuser"
#     public_key = file("~/.ssh/id_rsa.pub")
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "18.04-LTS"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }
# }

resource "azurerm_linux_virtual_machine" "web-vm" {
  name                            = "${var.prefix}-web-vm"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = "Standard_D2_v2"
  admin_username                  = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.web-nic.id,
  ]

  admin_ssh_key {
    username = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}