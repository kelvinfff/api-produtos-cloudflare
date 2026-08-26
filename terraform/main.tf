terraform {
    required_providers {
      cloudflare = {
        source = "cloudflare/cloudflare"
      }
    }
}

provider "cloudflare" {

}

resource "cloudflare_d1_database" "produtos" {
    account_id = var.cloudflare_account_id
    name = "produtos-db"
}