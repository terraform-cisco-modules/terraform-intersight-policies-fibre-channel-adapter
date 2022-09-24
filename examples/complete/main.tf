module "fibre_channel_adapter" {
  source  = "terraform-cisco-modules/policies-fibre-channel-adapter/intersight"
  version = ">= 1.0.1"

  adapter_template = "WindowsBoot"
  description      = "default Fibre Channel Adapter Adapter Policy."
  name             = "default"
  organization     = "default"
}
