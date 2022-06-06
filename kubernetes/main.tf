terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.8.0"
    }
  }
  # using own tfstate
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "nikitabulatovtfstate"
    container_name       = "tfstate"
    key                  = "kubernetes/terraform.tfstate"
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

# using global variables
data "terraform_remote_state" "kubernetes" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate"
    storage_account_name = "nikitabulatovtfstate"
    container_name       = "tfstate"
    key                  = "globalvars/terraform.tfstate"
  }
}

# using key vault for sensetive data
data "azurerm_key_vault" "example" {
  name                = "bulat"
  resource_group_name = "key_vault"
}


# using key vault for sensetive data
data "azurerm_key_vault_secret" "test" {
  name         = "test"
  key_vault_id = data.azurerm_key_vault.example.id
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    environment     = var.environment_name
    user            = data.terraform_remote_state.kubernetes.outputs.user_name
    key_vault_value = data.azurerm_key_vault_secret.test.value
  }
}






# using remote modules
module "vnet" {

  source = "github.com/JuMasta/terra-modules.git/vnet"

  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  vnet_name           = "nikita.bulatov"
  address_spaces      = ["10.0.0.0/8"]
  environment_name    = var.environment_name
  subnets = {
    "pod_subnet" = {
      address_prefixes = ["10.0.0.0/16"]
    }
    "node_subnet" = {
      address_prefixes = ["10.1.0.0/16"]
    }
  }

}

# using remote modules
module "kubernetes" {
  source              = "github.com/JuMasta/terra-modules.git/kubernetes"
  cluster_name        = "bulat"
  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  vm_size             = "standard_d2a_v4"
  dns_prefix          = "bulat"
  vnet_subnet_id      = module.vnet.subnets_id["node_subnet"]
  pod_subnet_id       = module.vnet.subnets_id["pod_subnet"]
  environment_name    = var.environment_name
}
