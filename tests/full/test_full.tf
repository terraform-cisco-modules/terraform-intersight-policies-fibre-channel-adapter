module "main" {
  source           = "../.."
  adapter_template = "VMware"
  description      = "${var.name} Fibre-Channel Adapter Policy."
  name             = var.name
  organization     = "terratest"
}
