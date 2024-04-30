terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws        = ">= 4.8.0"
    local      = ">= 1.4"
    #null       = ">= 2.1"
    template   = ">= 2.1"
    random     = ">= 2.1"
    kubernetes = ">= 1.9.0"
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }   
  }
}