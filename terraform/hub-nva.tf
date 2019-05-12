# Define local variables (check globals in parameters file)

locals {
  prefix-hub-nva         = "hub-nva"
  hub-nva-location       = "uksouth"
  hub-nva-resource-group = "hub-nva-rg"
}

# Create Resource Group for NVA

resource "azurerm_resource_group" "hub-nva-rg" {
  name     = "${local.prefix-hub-nva}-rg"
  location = "${local.hub-nva-location}"

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NIC1 for NVA1

resource "azurerm_network_interface" "hub-nva1-nic1" {
  name                 = "${local.prefix-hub-nva}-nic1"
  location             = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-nva-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub-nva}"
    subnet_id                     = "${azurerm_subnet.hub-public.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.4"
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NIC2 for NVA1

resource "azurerm_network_interface" "hub-nva1-nic2" {
  name                 = "${local.prefix-hub-nva}-nic2"
  location             = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-nva-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub-nva}"
    subnet_id                     = "${azurerm_subnet.hub-private.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.132"
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NIC1 for NVA2

resource "azurerm_network_interface" "hub-nva2-nic1" {
  name                 = "${local.prefix-hub-nva}-nic1"
  location             = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-nva-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub-nva}"
    subnet_id                     = "${azurerm_subnet.hub-public.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.5"
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NIC2 for NVA2

resource "azurerm_network_interface" "hub-nva2-nic2" {
  name                 = "${local.prefix-hub-nva}-nic2"
  location             = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-nva-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub-nva}"
    subnet_id                     = "${azurerm_subnet.hub-private.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.133"
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NVA1 and attach NICS

resource "azurerm_virtual_machine" "hub-nva1-vm" {
  name                  = "${local.prefix-hub-nva}-vm"
  location              = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-nva-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva1-nic1.id}" "${azurerm_network_interface.hub-nva1-nic2.id}"]
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
    computer_name  = "${local.prefix-hub-nva}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Create NVA2 and attach NICS

resource "azurerm_virtual_machine" "hub-nva2-vm" {
  name                  = "${local.prefix-hub-nva}-vm"
  location              = "${azurerm_resource_group.hub-nva-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-nva-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva2-nic1.id}" "${azurerm_network_interface.hub-nva2-nic2.id}"]
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
    computer_name  = "${local.prefix-hub-nva}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-hub-nva}"
  }
}

# Can this be modified to support applying the Cisco config or should a bootstrap be used?

#resource "azurerm_virtual_machine_extension" "enable-routes" {
#  name                 = "enable-iptables-routes"
#  location             = "${azurerm_resource_group.hub-nva-rg.location}"
#  resource_group_name  = "${azurerm_resource_group.hub-nva-rg.name}"
#  virtual_machine_name = "${azurerm_virtual_machine.hub-nva-vm.name}"
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.0"
#
#  settings = <<SETTINGS
#    {
#        "fileUris": [
#        "https://raw.githubusercontent.com/mspnp/reference-architectures/master/scripts/linux/enable-ip-forwarding.sh"
#        ],
#        "commandToExecute": "bash enable-ip-forwarding.sh"
#    }
#SETTINGS
#
#  tags {
#    environment = "${local.prefix-hub-nva}"
#  }
#}
