# Set local variables (check globals in variables file)

locals {
  spoke1-location       = "uksouth"
  spoke1-resource-group = "spoke1-vnet-rg"
  prefix-spoke1         = "spoke1"
}

# Create Spoke Resource Group

resource "azurerm_resource_group" "spoke1-vnet-rg" {
  name     = "${local.spoke1-resource-group}"
  location = "${local.spoke1-location}"
}

# Create Spoke VNET and set CIDR

resource "azurerm_virtual_network" "spoke1-vnet" {
  name                = "spoke1-vnet"
  location            = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  address_space       = ["10.74.10.0/24"]

  tags {
    environment = "${local.prefix-spoke1 }"
  }
}

# Create Spoke Private Subnet

resource "azurerm_subnet" "spoke1-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke1-vnet.name}"
  address_prefix       = "10.74.10.128/25"
}

# Create Spoke Public Subnet

resource "azurerm_subnet" "spoke1-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke1-vnet.name}"
  address_prefix       = "10.74.10.0/25"
}

# Create Peer from Spoke to Hub

resource "azurerm_virtual_network_peering" "spoke1-hub-peer" {
  name                      = "spoke1-hub-peer"
  resource_group_name       = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke1-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.hub-vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
  depends_on = ["azurerm_virtual_network.spoke1-vnet", "azurerm_virtual_network.hub-vnet"]
}

# Create Spoke NIC

resource "azurerm_network_interface" "spoke1-nic" {
  name                 = "${local.prefix-spoke1}-nic"
  location             = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-spoke1}"
    subnet_id                     = "${azurerm_subnet.spoke1-private.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

# Create Spoke VM

resource "azurerm_virtual_machine" "spoke1-vm" {
  name                  = "${local.prefix-spoke1}-vm"
  location              = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.spoke1-nic.id}"]
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
    computer_name  = "${local.prefix-spoke1}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-spoke1}"
  }
}

# Create Peer from Hub to Spoke

resource "azurerm_virtual_network_peering" "hub-spoke1-peer" {
  name                      = "hub-spoke1-peer"
  resource_group_name       = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.spoke1-vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
  depends_on = ["azurerm_virtual_network.spoke1-vnet", "azurerm_virtual_network.hub-vnet"]
}

# Create Spoke RT

resource "azurerm_route_table" "spoke1-rt" {
  name                          = "spoke1-rt"
  location                      = "${azurerm_resource_group.spoke1-vnet-rg.location}"
  resource_group_name           = "${azurerm_resource_group.spoke1-vnet-rg.name}"
  disable_bgp_route_propagation = false

  route {
    name                   = "toHub"
    address_prefix         = "10.0.0.0/8"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.74.9.132"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "vnetlocal"
  }

  tags {
    environment = "${local.prefix-spoke1}"
  }
}

# Associate Spoke RT with private subnet

resource "azurerm_subnet_route_table_association" "spoke1-rt-spoke1-vnet-private" {
  subnet_id      = "${azurerm_subnet.spoke1-private.id}"
  route_table_id = "${azurerm_route_table.spoke1-rt.id}"
  depends_on = ["azurerm_subnet.spoke1-private"]
}
