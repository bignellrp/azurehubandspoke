locals {
  onprem-location       = "ukwest"
  onprem-resource-group = "onprem-vnet-rg"
  prefix-onprem         = "onprem"
}

resource "azurerm_resource_group" "onprem-vnet-rg" {
  name     = "${local.onprem-resource-group}"
  location = "${local.onprem-location}"
}

resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"
  address_space       = ["10.0.0.0/16"]

  tags {
    environment = "${local.prefix-onprem}"
  }
}

resource "azurerm_subnet" "onprem-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.onprem-vnet.name}"
  address_prefix       = "10.0.0.0/24"
}

resource "azurerm_subnet" "onprem-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.onprem-vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

resource "azurerm_public_ip" "onprem-pip" {
    name                = "${local.prefix-onprem}-pip"
    location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
    resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"
    allocation_method   = "Dynamic"

    tags {
        environment = "${local.prefix-onprem}"
    }
}

resource "azurerm_network_interface" "onprem-nic" {
  name                 = "${local.prefix-onprem}-nic"
  location             = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-onprem}"
    subnet_id                     = "${azurerm_subnet.onprem-private.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.onprem-pip.id}"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "onprem-nsg" {
    name                = "${local.prefix-onprem}-nsg"
    location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
    resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"

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

    tags {
        environment = "onprem"
    }
}

resource "azurerm_subnet_network_security_group_association" "mgmt-nsg-association" {
  subnet_id                 = "${azurerm_subnet.onprem-private.id}"
  network_security_group_id = "${azurerm_network_security_group.onprem-nsg.id}"
}

resource "azurerm_virtual_machine" "onprem-vm" {
  name                  = "${local.prefix-onprem}-vm"
  location              = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.onprem-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.onprem-nic.id}"] # Need to add an additional NIC
  vm_size               = "${var.vmsize}"

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
    computer_name  = "${local.prefix-onprem}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-onprem}"
  }
}
