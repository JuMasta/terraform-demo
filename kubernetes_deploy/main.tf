terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.1"
    }
  }
  # own tfstate file (isolate tfstate)
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "nikitabulatovtfstate"
    container_name       = "tfstate"
    key                  = "kubernetes_deploy/terraform.tfstate"
  }
  required_version = ">= 1.1.0"
}


provider "azurerm" {
  features {}
}

# using remote state of "kubernetes" here I use outputs (k8s certificate key and ca_cert) for access 
data "terraform_remote_state" "kubernetes" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate"
    storage_account_name = "nikitabulatovtfstate"
    container_name       = "tfstate"
    key                  = "kubernetes/terraform.tfstate"
  }
}

# using locals for imporving readability
locals {
  host                   = data.terraform_remote_state.kubernetes.outputs.kube_config.*.host
  client_certificate     = data.terraform_remote_state.kubernetes.outputs.kube_config.*.client_certificate
  client_key             = data.terraform_remote_state.kubernetes.outputs.kube_config.*.client_key
  cluster_ca_certificate = data.terraform_remote_state.kubernetes.outputs.kube_config.*.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = local.host[0]
    client_certificate     = base64decode(local.client_certificate[0])
    client_key             = base64decode(local.client_key[0])
    cluster_ca_certificate = base64decode(local.cluster_ca_certificate[0])
  }
}



resource "helm_release" "argo-cd" {

  name             = "argo-release"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  verify           = false

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = "$2a$10$.TFIkSpF72qB1CyMvKuB5uxK5MIXu4ibzAJD2bKOYNPUIpwNOGQq."
  }

  set {
    name  = "server.ingress.enabled"
    value = true
  }

  set {
    name  = "server.ingress.annotations"
    value = jsonencode("${var.annotations}")
  }

  set {
    name  = "server.ingress.hosts"
    value = "{${join(",", var.host)}}"
  }

  set {
    name  = "server.ingress.https"
    value = false
  }

  set {
    name  = "server.ingress.ingressClassName"
    value = var.ingressClassName
  }

  set {
    name  = "server.extraArgs"
    value = "{${join(",", var.argo-args)}}"
  }

}




resource "helm_release" "nginx-controller" {

  name             = "nginx-release"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "nginx-ingress"
  create_namespace = true
  verify           = false
  set {
    name  = "controller.ingressClassResource.name"
    value = var.ingressClassName
  }

  set {
    name  = "controller.ingressClassResource.controllerValue"
    value = "k8s.io/ingress-nginx"
  }

  set {
    name  = "controller.ingressClassResource.enabled"
    value = true
  }

  set {
    name  = "controller.ingressClassByName"
    value = true
  }

}
