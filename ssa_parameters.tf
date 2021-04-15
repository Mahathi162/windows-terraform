#provider "azurerm" {
  #version = "=2.5.0"
#subscription_id = "c90e3d0d-7080-4628-b93b-0107fa7a76e7"

locals{
    tags ={environment = "Prep"}
    region = "eastus"
    gid = "CMC-SSA01"
    class_size = "2"
    vm_username = "mm185548user"
    vm_password = "P@ssword1234!"
}

