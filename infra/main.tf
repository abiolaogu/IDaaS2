# Placeholder for Terraform infrastructure configuration.
# This file should be populated with the necessary resources to provision the IDaaS platform.
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

resource "kubernetes_namespace" "idaas" {
  metadata {
    name = "idaas"
  }
}
