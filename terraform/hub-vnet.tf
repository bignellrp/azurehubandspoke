locals {
  prefix-hub         = "hub"
  hub-location       = "uksouth"
  hub-resource-group = "hub-vnet-rg"
}

resource "azurerm_resource_group" "hub-vnet-rg" {
  name     = "${local.hub-resource-group}"
  location = "${local.hub-location}"
}

resource "azurerm_virtual_network" "hub-vnet" {
  name                = "${local.prefix-hub}-vnet"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  address_space       = ["10.74.9.0/24"]

  tags {
    environment = "hub-spoke"
  }
}

resource "azurerm_subnet" "hub-private" {
  name                 = "private"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-vnet.name}"
  address_prefix       = "10.74.9.128/25"
}

resource "azurerm_subnet" "hub-public" {
  name                 = "public"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  virtual_network_name = "${azurerm_virtual_network.hub-vnet.name}"
  address_prefix       = "10.74.9.0/25"
}
