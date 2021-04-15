provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    subscription_id = "c90e3d0d-7080-4628-b93b-0107fa7a76e7"
    features {}
}
resource "azurerm_resource_group" "rg" {
  name     = "${local.gid}-rex-rg"
  location = local.region
}
resource "azurerm_availability_set" "Availset" {
  name                = "${local.gid}-availset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${local.gid}-vNet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_network_security_group" "nsg" {
  name                = "${local.gid}-nsg"
  location            = azurerm_resource_group.rg.location   
  resource_group_name = azurerm_resource_group.rg.name
  }
resource "azurerm_subnet" "subnet" {
  name                 = "${local.gid}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix       = "10.1.0.0/16"
}
resource "azurerm_public_ip" "publicip" {
  count               = local.class_size
  name                = "${local.gid}-control-ip-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "NIC" {
  count               = local.class_size
  name                = "${local.gid}-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipConfig"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.publicip[count.index].id
    private_ip_address            = "10.1.0.${count.index + 4}"
    private_ip_address_allocation = "Static"
  }
}
resource "azurerm_windows_virtual_machine" "win_vm" {
  count                 = local.class_size
  name                = "${local.gid}-vm-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "${local.vm_username}"
  admin_password      = "${local.vm_password}"
  availability_set_id = azurerm_availability_set.Availset.id
  network_interface_ids = [
    azurerm_network_interface.NIC[count.index].id,
  ]

  os_disk {
    name                 = "${local.gid}-vm-osdisk-${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}