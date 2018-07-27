# RG
# Create a resource group
resource "azurerm_resource_group" "RG" {
  name     = "RG-MMS-RandDMS"
  location = "westeurope"
}

# VNET(ONE)
# Create a virtual network within the resource group 
resource "azurerm_virtual_network" "VNET" {
  name                = "VNET-MMS-RandDMs"
  address_space       = ["10.5.0.0/16"]
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"
}

# SUBNET(THREE)
# Create a SUBNET within the resource group for RP
resource "azurerm_subnet" "RP" {
  name                 = "SUBNET-RP-MMS-RandDMs-DEV"
  resource_group_name  = "${azurerm_resource_group.RG.name}"
  virtual_network_name = "${azurerm_virtual_network.VNET.name}"
  address_prefix       = "10.5.1.0/24"
}

# Create a SUBNET within the resource group for dbWAS
resource "azurerm_subnet" "DBWAS" {
  name                 = "SUBNET-DBWAS-MMS-RandDMs-DEV"
  resource_group_name  = "${azurerm_resource_group.RG.name}"
  virtual_network_name = "${azurerm_virtual_network.VNET.name}"
  address_prefix       = "10.5.2.0/24"
}

# Create a SUBNET within the resource group for VPN GATEWAY
resource "azurerm_subnet" "VPN" {
  name                 = "GatewaySubnet"
  resource_group_name  = "${azurerm_resource_group.RG.name}"
  virtual_network_name = "${azurerm_virtual_network.VNET.name}"
  address_prefix       = "10.5.3.0/24"
}

# NSG(TWO)
# Create dbwas network security group
resource "azurerm_network_security_group" "DBWAS" {
  name                = "SUBNET-DBWAS-MMS-RandDMs-DEV"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"
}

# Create RP network security group
resource "azurerm_network_security_group" "RP" {
  name                = "SUBNET-RP-MMS-RandDMs-DEV"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"
}

resource "azurerm_network_security_rule" "RP" {
  name                        = "allow-port-22"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.RG.name}"
  network_security_group_name = "${azurerm_network_security_group.RP.name}"
}

resource "azurerm_network_security_rule" "DBWAS" {
  name                        = "allow-rdp"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.RG.name}"
  network_security_group_name = "${azurerm_network_security_group.DBWAS.name}"
}

# PUBLIC IP (TWO)
# Create the public ip for rp
resource "azurerm_public_ip" "RP" {
  name                         = "IPP-RP-MMS-RandDMs"
  location                     = "${azurerm_resource_group.RG.location}"
  resource_group_name          = "${azurerm_resource_group.RG.name}"
  public_ip_address_allocation = "Static"
}

# Create the public ip for VPN
resource "azurerm_public_ip" "VPN" {
  name                         = "IPP-VPN-MMS-RandDMs"
  location                     = "${azurerm_resource_group.RG.location}"
  resource_group_name          = "${azurerm_resource_group.RG.name}"
  public_ip_address_allocation = "Dynamic"
}

# INTERFACE(THREE)
# Create the RP interface
resource "azurerm_network_interface" "RP" {
  name                = "IR-RP-MMS-RandDMs-DEV"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"

  ip_configuration {
    name                          = "config-privateip-rp"
    subnet_id                     = "${azurerm_subnet.RP.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.5.1.4"
    public_ip_address_id          = "${azurerm_public_ip.RP.id}"
  }
}

# Create the database interface
resource "azurerm_network_interface" "DB" {
  name                = "IR-DB-MMS-RandDMs-DEV"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"

  ip_configuration {
    name                          = "config-privateip-db"
    subnet_id                     = "${azurerm_subnet.DBWAS.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.5.2.4"
  }
}

# Create the database interface
resource "azurerm_network_interface" "WAS" {
  name                = "IR-WAS-MMS-RandDMs-DEV"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"

  ip_configuration {
    name                          = "config-privateip-was"
    subnet_id                     = "${azurerm_subnet.DBWAS.id}"
    private_ip_address_allocation = "static"
    private_ip_address            = "10.5.2.5"
  }
}

# STORAGE ACCOUNT(THREE)
# Create the RP storage account

resource "azurerm_storage_account" "RP" {
  name                     = "csrpmmsranddms"
  resource_group_name      = "${azurerm_resource_group.RG.name}"
  location                 = "${azurerm_resource_group.RG.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the DB storage account
resource "azurerm_storage_account" "DB" {
  name                     = "csdbmmsranddms"
  resource_group_name      = "${azurerm_resource_group.RG.name}"
  location                 = "${azurerm_resource_group.RG.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create the WAS storage account
resource "azurerm_storage_account" "WAS" {
  name                     = "cswasmmsranddms"
  resource_group_name      = "${azurerm_resource_group.RG.name}"
  location                 = "${azurerm_resource_group.RG.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# STORAGE CONTAINERS(THREE)
# Create the RP storage container

resource "azurerm_storage_container" "RP" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  storage_account_name  = "${azurerm_storage_account.RP.name}"
  container_access_type = "private"
}

# Create the DB storage container
resource "azurerm_storage_container" "DB" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  storage_account_name  = "${azurerm_storage_account.DB.name}"
  container_access_type = "private"
}

# Create the WAS storage container
resource "azurerm_storage_container" "WAS" {
  name                  = "vhds"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  storage_account_name  = "${azurerm_storage_account.WAS.name}"
  container_access_type = "private"
}

# VMs(THREE)
# Create the RP VM
resource "azurerm_virtual_machine" "RP" {
  name                  = "VM-RP-MMS-RandDMs-DEV"
  location              = "${azurerm_resource_group.RG.location}"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  network_interface_ids = ["${azurerm_network_interface.RP.id}"]
  vm_size               = "Standard_F2s_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  #delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name          = "osdisk_RP"
    caching       = "ReadWrite"
    create_option = "FromImage"
    vhd_uri       = "${azurerm_storage_account.RP.primary_blob_endpoint}${azurerm_storage_container.RP.name}/osdisk_RP.vhd"
  }
  # Optional data disks
  storage_data_disk {
    name          = "datadisk_RP"
    vhd_uri       = "${azurerm_storage_account.RP.primary_blob_endpoint}${azurerm_storage_container.RP.name}/datadisk_RP.vhd"
    create_option = "Empty"
    lun           = 0
    disk_size_gb  = "20"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "${var.azure_VMAdminName}"
    admin_password = "${var.azure_VMAdminPassword}"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

# Create the DB VM
resource "azurerm_virtual_machine" "DB" {
  name                  = "VM-DB-MMS-RandDMs-DEV"
  location              = "${azurerm_resource_group.RG.location}"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  network_interface_ids = ["${azurerm_network_interface.DB.id}"]
  vm_size               = "Standard_D2s_v3"

  #vm_size               = "Standard B2ms"


  # Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  #delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name          = "osdisk_DB"
    caching       = "ReadWrite"
    create_option = "FromImage"
    vhd_uri       = "${azurerm_storage_account.DB.primary_blob_endpoint}${azurerm_storage_container.DB.name}/osdisk_DB.vhd"
  }
  # Optional data disks
  storage_data_disk {
    name          = "datadisk_DB"
    vhd_uri       = "${azurerm_storage_account.DB.primary_blob_endpoint}${azurerm_storage_container.DB.name}/datadisk_DB.vhd"
    create_option = "Empty"
    lun           = 0
    disk_size_gb  = "20"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "${var.azure_VMAdminName}"
    admin_password = "${var.azure_VMAdminPassword}"
  }
  os_profile_windows_config {
    enable_automatic_upgrades = false
  }
}

# l'extension sql server 
resource "azurerm_virtual_machine_extension" "DB" {
  name                 = "SqlIaasExtension"
  location             = "${azurerm_resource_group.RG.location}"
  resource_group_name  = "${azurerm_resource_group.RG.name}"
  virtual_machine_name = "${azurerm_virtual_machine.DB.name}"
  publisher            = "Microsoft.SqlServer.Management"
  type                 = "SqlIaaSAgent"
  type_handler_version = "1.2"

  settings = <<SETTINGS
  {
    "sqlConnectivityType": {
            "value": "Private"
    },
     "sqlPortNumber": {
            "value": 1433
    },
    "sqlStorageDisksCount": {
            "value": 1
     },
    "sqlStorageWorkloadType": {
            "value": "GENERAL"
    },
    "sqlStorageDisksConfigurationType": {
            "value": "NEW"
    },
    "sqlStorageStartingDeviceId": {
            "value": 2
    },
    "sqlStorageDeploymentToken": {
            "value": 34166
    },
    "sqlAutopatchingDayOfWeek": {
            "value": "Sunday"
    },
    "sqlAutopatchingStartHour": {
            "value": "2"
    },
    "sqlAutopatchingWindowDuration": {
            "value": "60"
     },
    "rServicesEnabled": {
            "value": "false"
    }
  }
SETTINGS
}

# Create the WAS VM
resource "azurerm_virtual_machine" "WAS" {
  name                  = "VM-WAS-MMS-RandDMs-DEV"
  location              = "${azurerm_resource_group.RG.location}"
  resource_group_name   = "${azurerm_resource_group.RG.name}"
  network_interface_ids = ["${azurerm_network_interface.WAS.id}"]
  vm_size               = "Standard_B2ms"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  #delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
  storage_os_disk {
    name          = "osdisk_WAS"
    caching       = "ReadWrite"
    create_option = "FromImage"
    vhd_uri       = "${azurerm_storage_account.WAS.primary_blob_endpoint}${azurerm_storage_container.WAS.name}/osdisk_WAS.vhd"
  }
  # Optional data disks
  storage_data_disk {
    name          = "datadisk_WAS"
    vhd_uri       = "${azurerm_storage_account.WAS.primary_blob_endpoint}${azurerm_storage_container.WAS.name}/datadisk_WAS.vhd"
    create_option = "Empty"
    lun           = 0
    disk_size_gb  = "20"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "${var.azure_VMAdminName}"
    admin_password = "${var.azure_VMAdminPassword}"
  }
  os_profile_windows_config {
    enable_automatic_upgrades = false
  }
}

# VPN
# Create the VPN
resource "azurerm_virtual_network_gateway" "VPN" {
  name                = "VPN-MMS-RandDMs"
  location            = "${azurerm_resource_group.RG.location}"
  resource_group_name = "${azurerm_resource_group.RG.name}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.VPN.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.VPN.id}"
  }

  vpn_client_configuration {
    address_space       = ["192.168.10.0/24"]
    vpn_client_protocol = ["SSTP"]

    root_certificate {
      name = "RandDMSRootCert"

      public_cert_data = <<EOF
MIIDDTCCAfWgAwIBAgIQJCnzpbSpi7ZCEhpULdb7BTANBgkqhkiG9w0BAQsFADAaMRgwFgYDVQQDEw9SYW5kRE1TUm9vdENlcnQwHhcNMTgwNjI4MDkzNzE5WhcNMzkxMjMxMjM1OTU5WjAaMRgwFgYDVQQDEw9SYW5kRE1TUm9vdENlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDDTLSA1X+dsZ6b2782ESerOmoo8tM1jsQDhuLWydWOx/FI4U17qb+E9u2fC8ia9Wr5tUbvb1f7ybDCNzLiByFICvSzjiOEkI4fEZ0P13Hk0LAsMTmuypxb6c29sqaMTQBbK0zM4cWlium1jVAvCheEz1ceGUru5X4bbZocuNQ+gUtI2a02y0SY91FBjL/beB0Mzn3Mm1xQlpg/q9GlnYbJM+1cATWS0o4c/Xzv0fwMUxsjC/U5F2egIscetlig1FL1Cjh5fQE/WDHL3FOEs2yVOr6ydlo8CBkBoGEWdsSznu/z8ejHecrc8XYBLn22jJCHd0UunmMZHDBXhL3vNi0VAgMBAAGjTzBNMEsGA1UdAQREMEKAEDyydXjFzwUyio633N0IQVShHDAaMRgwFgYDVQQDEw9SYW5kRE1TUm9vdENlcnSCECQp86W0qYu2QhIaVC3W+wUwDQYJKoZIhvcNAQELBQADggEBAAz7x6sqq+eEZEhFuvgzYWTPhTZSnok75FsHU9bHLksDaQnZKk4pj+NC54mJ2KMsIf+tsvgedk1ccxBzIBYUkQnmgoIuiIOyCeH/ddJxYEmCeZ4Hy/ftbb4z1pwoSstw9sijxADCDcVLB9QlCO9V/ehMSYbvtFNc5pbciz5viaC/qmN7e755FUuMWPMWu9pL0s62ANvhqbaqf8SgSjuRKhBAgLxDTHHNJVr1+n1xmTaVpwiSPLkyMbqPqT10GGvHPwIYSzxwqvP+Qhysc0oHr0GtYJh/Z24cDvs53O13iwdKfn5CuBh2GTczUDrH12z7b5TLc4pyPX2nZ6NDzAicdz4=
EOF
    }
  }
}
