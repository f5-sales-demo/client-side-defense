terraform {
  required_version = ">= 1.14.0"

  backend "s3" {
    bucket              = "terraform-tfstate-xc"
    key                 = "f5-sales-demo/client-side-defense-system-notifications.tfstate"
    region              = "us-east-1"
    allowed_account_ids = ["280469140135"]
    use_lockfile        = true
    encrypt             = true
  }

  required_providers {
    xcsh = {
      source  = "f5-sales-demo/xcsh"
      version = "15.2.0"
    }
  }
}

provider "xcsh" {
  api_url = "https://f5-sales-demo.console.ves.volterra.io/api"
}
