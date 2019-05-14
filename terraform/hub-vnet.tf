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

# Create Public IP for NVA1

resource "azurerm_public_ip" "nva1_public" {
  name                 = "${local.prefix-hub}-pubip1"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
#  zones               = ["1"]
}

# Create Public IP for NVA2

resource "azurerm_public_ip" "nva2_public" {
  name                 = "${local.prefix-hub}-pubip2"
  location             = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name  = "${azurerm_resource_group.hub-vnet-rg.name}"
  allocation_method   = "Static"
  sku                 = "Standard"
#  zones               = ["2"]
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
    public_ip_address_id          = "${azurerm_public_ip.nva1_public.id}"
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
#    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.azlb.id}"]
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
    public_ip_address_id          = "${azurerm_public_ip.nva2_public.id}"
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
#    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.azlb.id}"]
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NVA1 and attach NICS

resource "azurerm_virtual_machine" "hub-nva1-vm" {
  name                  = "${local.prefix-hub}-nva1"
  location              = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva1-nic1.id}", "${azurerm_network_interface.hub-nva1-nic2.id}"]
  primary_network_interface_id = "${azurerm_network_interface.hub-nva1-nic1.id}"
  vm_size               = "${var.vmsize}"
#  zones                 = ["1"]

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "16_10-payg-sec"
    version   = "16.10.120190108"
  }

  plan {
    name      = "16_10-payg-sec"
    publisher = "cisco"
    product   = "cisco-csr-1000v"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-hub}-nva1"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
    custom_data    = "${file("customdatacsr1.txt")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create NVA2 and attach NICS

resource "azurerm_virtual_machine" "hub-nva2-vm" {
  name                  = "${local.prefix-hub}-nva2"
  location              = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name   = "${azurerm_resource_group.hub-vnet-rg.name}"
  network_interface_ids = ["${azurerm_network_interface.hub-nva2-nic1.id}", "${azurerm_network_interface.hub-nva2-nic2.id}"]
  primary_network_interface_id = "${azurerm_network_interface.hub-nva2-nic1.id}"
  vm_size               = "${var.vmsize}"
#  zones                 = ["2"]

  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-csr-1000v"
    sku       = "16_10-payg-sec"
    version   = "16.10.120190108"
  }

  plan {
    name      = "16_10-payg-sec"
    publisher = "cisco"
    product   = "cisco-csr-1000v"
  }

  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${local.prefix-hub}-nva2"
    admin_username = "${var.username}"
    admin_password = "${var.password}"
    custom_data    = "${file("customdatacsr2.txt")}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags {
    environment = "${local.prefix-hub}"
  }
}

# Create LB

resource "azurerm_lb" "azlb" {
  name                = "${local.prefix-hub}-lb"
  location            = "${azurerm_resource_group.hub-vnet-rg.location}"
  resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"
  sku                 = "Standard"

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

# Create AddressPool

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
  idle_timeout_in_minutes        = "5"
  probe_id                       = "${azurerm_lb_probe.azlb.id}"
  depends_on                     = ["azurerm_lb_probe.azlb"]
}

# Associate IPs to Address Pool

resource "azurerm_network_interface_backend_address_pool_association" "lb_assoc_nva1" {
  network_interface_id    = "${azurerm_network_interface.hub-nva1-nic2.id}"
  ip_configuration_name   = "${azurerm_network_interface.hub-nva1-nic2.ip_configuration.0.name}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.azlb.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_assoc_nva2" {
  network_interface_id    = "${azurerm_network_interface.hub-nva2-nic2.id}"
  ip_configuration_name   = "${azurerm_network_interface.hub-nva2-nic2.ip_configuration.0.name}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.azlb.id}"
}

# Create Network Security Group and rule

resource "azurerm_network_security_group" "nva-nsg" {
    name                = "${local.prefix-hub}-nsg"
    location            = "${azurerm_resource_group.hub-vnet-rg.location}"
    resource_group_name = "${azurerm_resource_group.hub-vnet-rg.name}"

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
        environment = "local.prefix-hub"
    }
}

# Associate NSG with Private Subnet

resource "azurerm_subnet_network_security_group_association" "private-nsg-association" {
  subnet_id                 = "${azurerm_subnet.hub-private.id}"
  network_security_group_id = "${azurerm_network_security_group.nva-nsg.id}"
}
