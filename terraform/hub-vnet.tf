# Define local variables (check globals in parameters file)

locals {
  prefix-hub            = "hub"
  hub-location          = "uksouth"
  hub-resource-group    = "hub-vnet-rg"
}

# Create Hub Resource Group

resource "azurerm_resource_group" "hub-vnet-rg" {
  name     = "${local.hub-resource-group}"
  location = "${local.hub-location}"
}

# Create Hub VNET and set CIDR

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  address_space       = ["10.74.9.0/24"]

  tags {
    environment = "hub-spoke"
  }
}

# Create Hub Private Subnet

resource "azurerm_subnet" "hub-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-vnet.name}"
  address_prefix       = "10.74.9.128/25"
}

# Create Hub Public Subnet

resource "azurerm_subnet" "hub-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-vnet.name}"
  address_prefix       = "10.74.9.0/25"
}

# Create LB

resource "azurerm_lb" "azlb" {
  name                = "${local.prefix-hub}-lb"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"

  frontend_ip_configuration {
    name                          = "${local.prefix-hub}-fip"
    subnet_id                     = "${azurerm_subnet.hub-private.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.134"
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create AddressPool - Not sure how to add addresses

resource "azurerm_lb_backend_address_pool" "azlb" {
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  loadbalancer_id     = "${azurerm_lb.azlb.id}"
  name                = "BackEndAddressPool"
}

# Create LB Probe

resource "azurerm_lb_probe" "azlb" {
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  loadbalancer_id     = "${azurerm_lb.azlb.id}"
  name                = "${local.prefix-hub}-probe"
  protocol            = "tcp"
  port                = "22"
  interval_in_seconds = "5"
  number_of_probes    = "2"
}

# Create LB Rule

resource "azurerm_lb_rule" "azlb" {
  resource_group_name            = "${azurerm_resource_group.hub-vnet-rg.name}"
  loadbalancer_id                = "${azurerm_lb.azlb.id}"
  name                           = "${local.prefix-hub}-rule"
  protocol                       = "All"
  frontend_port                  = "0"
  backend_port                   = "0"
  frontend_ip_configuration_name = "${local.prefix-hub}-fip"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.azlb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.azlb.id}"
  depends_on                     = ["azurerm_lb_probe.azlb"]
}
