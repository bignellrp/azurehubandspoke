# Set local variables (check globals in variables file)

locals {
  onprem-location       = "ukwest"
  onprem-resource-group = "onprem-vnet-rg"
  prefix-onprem         = "onprem"
}

# Create Onprem Resource Group

resource "azurerm_resource_group" "onprem-vnet-rg" {
  name     = "${local.onprem-resource-group}"
  location = "${local.onprem-location}"
}

# Create Onprem VNET and set CIDR

resource "azurerm_virtual_network" "onprem-vnet" {
  name                = "onprem-vnet"
  location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"
  address_space       = ["10.0.0.0/16"]

  tags {
    environment = "${local.prefix-onprem}"
  }
}

# Create Onprem Public Subnet

resource "azurerm_subnet" "onprem-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.onprem-vnet.name}"
  address_prefix       = "10.0.0.0/24"
}

# Create Onprem Private Subnet

resource "azurerm_subnet" "onprem-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.onprem-vnet.name}"
  address_prefix       = "10.0.1.0/24"
}

# Create PublicIP for VM

resource "azurerm_public_ip" "onprem-pip1" {
    name                = "${local.prefix-onprem}-pip1"
    location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
    resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"
    allocation_method   = "Dynamic"

    tags {
        environment = "${local.prefix-onprem}"
    }
}

# Create PublicIP for Onprem Router VM

resource "azurerm_public_ip" "onprem-pip2" {
    name                = "${local.prefix-onprem}-pip2"
    location            = "${azurerm_resource_group.onprem-vnet-rg.location}"
    resource_group_name = "${azurerm_resource_group.onprem-vnet-rg.name}"
    allocation_method   = "Dynamic" # Need to change this to static

    tags {
        environment = "${local.prefix-onprem}"
    }
}

# Create NIC for VM

resource "azurerm_network_interface" "onprem-nic" {
  name                 = "${local.prefix-onprem}-nic"
  location             = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-onprem}"
    subnet_id                     = "${azurerm_subnet.onprem-private.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.onprem-pip1.id}"
  }
}

# Create NIC1 for Router VM

resource "azurerm_network_interface" "onprem-rtr-nic1" {
  name                 = "${local.prefix-onprem}-rtr-nic1"
  location             = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-onprem}"
    subnet_id                     = "${azurerm_subnet.onprem-public.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.onprem-pip2.id}"
    primary                       = "true"
  }
}

# Create NIC2 for Router VM

resource "azurerm_network_interface" "onprem-rtr-nic2" {
  name                 = "${local.prefix-onprem}-rtr-nic2"
  location             = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.onprem-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-onprem}"
    subnet_id                     = "${azurerm_subnet.onprem-private.id}"
    private_ip_address_allocation = "Dynamic"
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

# Associate NSG with Private Subnet

resource "azurerm_subnet_network_security_group_association" "private-nsg-association" {
  subnet_id                 = "${azurerm_subnet.onprem-private.id}"
  network_security_group_id = "${azurerm_network_security_group.onprem-nsg.id}"
}

# Create Onprem VM

resource "azurerm_virtual_machine" "onprem-vm" {
  name                  = "${local.prefix-onprem}-vm"
  location              = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.onprem-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.onprem-nic.id}"]
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

# Create Onprem Router VM

resource "azurerm_virtual_machine" "onprem-rtr-vm" {
  name                  = "${local.prefix-onprem}-rtr-vm"
  location              = "${azurerm_resource_group.onprem-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.onprem-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.onprem-rtr-nic1.id}"] # Needs a second interface
  vm_size               = "${var.vmsize}"

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2"
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
