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

# Create NIC1 for NVA1

resource "azurerm_network_interface" "hub-nva1-nic1" {
  name                 = "${local.prefix-hub}-nic1"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub}"
    subnet_id                     = "${azurerm_subnet.hub-public.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.4"
    primary                       = "true"
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NIC2 for NVA1

resource "azurerm_network_interface" "hub-nva1-nic2" {
  name                 = "${local.prefix-hub}-nic2"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub}"
    subnet_id                     = "${azurerm_subnet.hub-private.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.132"
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NIC1 for NVA2

resource "azurerm_network_interface" "hub-nva2-nic1" {
  name                 = "${local.prefix-hub}-nic1"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub}"
    subnet_id                     = "${azurerm_subnet.hub-public.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.5"
    primary                       = "true"
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NIC2 for NVA2

resource "azurerm_network_interface" "hub-nva2-nic2" {
  name                 = "${local.prefix-hub}-nic2"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "${local.prefix-hub}"
    subnet_id                     = "${azurerm_subnet.hub-private.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.74.9.133"
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NVA1 and attach NICS

resource "azurerm_virtual_machine" "hub-nva1-vm" {
  name                  = "${local.prefix-hub}-vm"
  location              = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva1-nic1.id}", "${azurerm_network_interface.hub-nva1-nic2.id}"]
  primary_network_interface_id = "${azurerm_network_interface.hub-nva1-nic1.id}"
  vm_size               = "${var.vmsize}"

  storage_image_reference {
    publisher = "Cisco"
    offer     = "Cisco-CSR-1000V"
    sku       = "csr-azure-payg"
    version   = "3.16.10"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-hub}-vm"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NVA2 and attach NICS

#resource "azurerm_virtual_machine" "hub-nva2-vm" {
#  name                  = "${local.prefix-hub}-vm"
#  location              = "${azurerm_resource_group.hub-vnet-rg.location}"
#  resource_group_name   = "${azurerm_resource_group.hub-vnet-rg.name}"
#  network_interface_ids = ["${azurerm_network_interface.hub-nva2-nic1.id}"]  # Needs a second interface
#  vm_size               = "${var.vmsize}"
#
#  storage_image_reference {
#    publisher = "Canonical"
#    offer     = "UbuntuServer"
#    sku       = "16.04-LTS"
#    version   = "latest"
#  }

#  storage_os_disk {
#    name              = "myosdisk2"
#    caching           = "ReadWrite"
#    create_option     = "FromImage"
#    managed_disk_type = "Standard_LRS"
#  }

#  os_profile {
#    computer_name  = "${local.prefix-hub}-vm"
#    admin_username = "${var.username}"
#    admin_password = "${var.password}"
#  }

#  os_profile_linux_config {
#    disable_password_authentication = false
#  }

#  tags {
#    environment = "${local.prefix-hub}"
#  }
#}

# Can this be modified to support applying the Cisco config or should a bootstrap be used?

#resource "azurerm_virtual_machine_extension" "enable-routes" {
#  name                 = "enable-iptables-routes"
#  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
#  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
#  virtual_machine_name = "${azurerm_virtual_machine.hub-nva-vm.name}"
#  publisher            = "Microsoft.Azure.Extensions"
#  type                 = "CustomScript"
#  type_handler_version = "2.0"
#
#  settings = <<SETTINGS
#    {
#        "commandToExecute": "bash enable-ip-forwarding.sh"
#    }
#SETTINGS
#
#  tags {
#    environment = "${local.prefix-hub}"
#  }
#}

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
  protocol                       = "tcp" #All
  frontend_port                  = "80" #0
  backend_port                   = "80" #0
  frontend_ip_configuration_name = "${local.prefix-hub}-fip"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.azlb.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.azlb.id}"
  depends_on                     = ["azurerm_lb_probe.azlb"]
}
