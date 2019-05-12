# Set local variables (check globals in variables file)

locals {
  spoke2-location       = "uksouth"
  spoke2-resource-group = "spoke2-vnet-rg"
  prefix-spoke2         = "spoke2"
}

# Create Spoke Resource Group

resource "azurerm_resource_group" "spoke2-vnet-rg" {
  name     = "${local.spoke2-resource-group}"
  location = "${local.spoke2-location}"
}

# Create Spoke VNET and set CIDR

resource "azurerm_virtual_network" "spoke2-vnet" {
  name                = "${local.prefix-spoke2}-vnet"
  location            = "${azurerm_resource_group.spoke2-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  address_space       = ["10.74.11.0/24"]

  tags {
    environment = "${local.prefix-spoke2}"
  }
}

# Create Spoke Private Subnet

resource "azurerm_subnet" "spoke2-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke2-vnet.name}"
  address_prefix       = "10.74.11.128/25"
}

# Create Spoke Public Subnet

resource "azurerm_subnet" "spoke2-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.spoke2-vnet.name}"
  address_prefix       = "10.74.11.0/25"
}

# Create Peer from Spoke to Hub

resource "azurerm_virtual_network_peering" "spoke2-hub-peer" {
  name                      = "${local.prefix-spoke2}-hub-peer"
  resource_group_name       = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke2-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.hub-vnet.id}"

  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  allow_gateway_transit   = false
  use_remote_gateways     = false
  depends_on = ["azurerm_virtual_network.spoke2-vnet", "azurerm_virtual_network.hub-vnet"]
}

# Create Spoke NIC

resource "azurerm_network_interface" "spoke2-nic" {
  name                 = "${local.prefix-spoke2}-nic"
  location             = "${azurerm_resource_group.spoke2-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-spoke2}"
    subnet_id                     = "${azurerm_subnet.spoke2-private.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "${local.prefix-spoke2}"
  }
}

# Create Spoke VM

resource "azurerm_virtual_machine" "spoke2-vm" {
  name                  = "${local.prefix-spoke2}-vm"
  location              = "${azurerm_resource_group.spoke2-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.spoke2-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.spoke2-nic.id}"]
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
    computer_name  = "${local.prefix-spoke2}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-spoke2}"
  }
}

# Create Peer from Hub to Spoke

resource "azurerm_virtual_network_peering" "hub-spoke2-peer" {
  name                      = "hub-spoke2-peer"
  resource_group_name       = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.hub-vnet.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.spoke2-vnet.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic   = true
  allow_gateway_transit     = false
  use_remote_gateways       = false
  depends_on = ["azurerm_virtual_network.spoke2-vnet", "azurerm_virtual_network.hub-vnet"]
}

# Create Spoke RT

resource "azurerm_route_table" "spoke2-rt" {
  name                          = "spoke2-rt"
  location                      = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name           = "${azurerm_resource_group.hub-nva-rg.name}"
  disable_bgp_route_propagation = false

  route {
    name                   = "toHub"
    address_prefix         = "10.0.0.0/8"
    next_hop_in_ip_address = "10.74.9.132"
    next_hop_type          = "VirtualAppliance"
  }

  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "vnetlocal"
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Associate Spoke RT with private subnet

resource "azurerm_subnet_route_table_association" "spoke2-rt-spoke2-vnet-private" {
  subnet_id      = "${azurerm_subnet.spoke2-private.id}"
  route_table_id = "${azurerm_route_table.spoke2-rt.id}"
  depends_on = ["azurerm_subnet.spoke2-private"]
}
