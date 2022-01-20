terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {
      
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "prattesttwo"
  location = "westeurope"
}

resource "azurerm_virtual_network" "vnetfe" {
  name                = "vnetfe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "integrationsubnetfe" {
  name                 = "integrationsubnetfe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnetfe.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Web"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

data "azurerm_subnet" "vmsubnet"{
  name = "pratvnet"
  virtual_network_name = "netpratyush"
  resource_group_name = "prestest"
}


resource "azurerm_virtual_network" "vnetbe" {
  name                = "vnetbe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "integrationsubnetbe" {
  name                 = "integrationsubnetbe"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnetbe.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints = ["Microsoft.Web"]
  delegation {
    name = "delegation"
    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}


resource "azurerm_app_service_plan" "appserviceplanfe" {
  name                = "appserviceplanfe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind = "Linux"
  reserved = true
  sku {
    tier = "Premiumv2"
    size = "P1v2"
  }
}

resource "azurerm_app_service_plan" "appserviceplanbe" {
  name                = "appserviceplanbe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind = "Linux"
  reserved = true
  sku {
    tier = "Premiumv2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "frontwebapp" {
  name                = "frontwebapp2020081011"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplanfe.id

  site_config {
    linux_fx_version = "PYTHON|3.9"
  }
  app_settings = {
    "WEBSITE_DNS_SERVER": "168.63.129.16",
    "WEBSITE_VNET_ROUTE_ALL": "1"
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegrationconnection" {
  app_service_id  = azurerm_app_service.frontwebapp.id
  subnet_id       = azurerm_subnet.integrationsubnetfe.id
}

resource "azurerm_app_service" "backwebapp" {
  name                = "backwebapp2020081011"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.appserviceplanbe.id

  app_settings = {
      "WEBSITE_DNS_SERVER": "168.63.129.16",
      "WEBSITE_VNET_ROUTE_ALL": "1"
    }
  site_config {
    linux_fx_version = "PYTHON|3.9"
    ip_restriction {
      ip_address                = "80.113.23.202/32"
      priority                  = 1000
      name                      = "InternalAppSubnet"
      action                    = "Allow"
      service_tag               = null
      virtual_network_subnet_id = null
    }
    ip_restriction {
      ip_address                = null
      priority                  = 1000
      name                      = "InternalAppSubnet"
      action                    = "Allow"
      service_tag               = null
      virtual_network_subnet_id = azurerm_subnet.integrationsubnetfe.id
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnetintegrationconnectionbe" {
  app_service_id  = azurerm_app_service.backwebapp.id
  subnet_id       = data.azurerm_subnet.vmsubnet.id
}
