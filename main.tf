#____________________________________________________________
#
# Intersight Organization Data Source
# GUI Location: Settings > Settings > Organizations > {Name}
#____________________________________________________________

data "intersight_organization_organization" "org_moid" {
  name = var.organization
}

#__________________________________________________________________
#
# Intersight Fibre Channel Adapter Policy
# GUI Location: Policies > Create Policy > Fibre Channel Adapter
#__________________________________________________________________

resource "intersight_vnic_fc_adapter_policy" "fibre_channel_adapter" {
  depends_on = [
    data.intersight_organization_organization.org_moid
  ]
  description                 = length(
        regexall("(FCNVMeInitiator)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for FCNVMeInitiator." : length(
        regexall("(FCNVMeTarget)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for FCNVMeTarget." : length(
        regexall("(Initiator)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for Initiator." : length(
        regexall("(Linux)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for linux." : length(
        regexall("(Solaris)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for Solaris." : length(
        regexall("(VMware)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for VMware." : length(
        regexall("(WindowsBoot)", coalesce(var.adapter_template, "EMPTY"))) > 0 ? "Recommended adapter settings for WindowsBoot." : length(
        regexall("(Windows)", coalesce(var.adapter_template, "EMPTY"))
      ) > 0 ? "Recommended adapter settings for Windows." : var.description != "" ? var.description : "${var.name} Fibre-Channel Adapter Policy."
  error_detection_timeout     = var.error_detection_timeout
  io_throttle_count           = var.io_throttle_count
  lun_count                   = var.max_luns_per_target
  lun_queue_depth             = var.lun_queue_depth
  name                        = var.name
  resource_allocation_timeout = var.resource_allocation_timeout
  error_recovery_settings {
    enabled           = var.enable_fcp_error_recovery
    io_retry_count    = var.error_recovery_port_down_io_retry
    io_retry_timeout  = var.error_recovery_io_retry_timeout
    link_down_timeout = var.error_recovery_link_down_timeout
    port_down_timeout = var.adapter_template == "WindowsBoot" ? 5000 : length(
        regexall("(FCNVMeInitiator|Initiator|Solaris|VMware|Windows)", coalesce(var.adapter_template, "EMPTY"))
      ) > 0 ? 30000 : var.error_recovery_port_down_timeout
  }
  flogi_settings {
    retries = var.flogi_retries
    timeout = var.flogi_timeout
  }
  interrupt_settings {
    mode = var.interrupt_mode
  }
  organization {
    moid        = data.intersight_organization_organization.org_moid.results[0].moid
    object_type = "organization.Organization"
  }
  plogi_settings {
    retries = var.plogi_retries
    timeout = var.adapter_template == "WindowsBoot" ? 4000 : var.plogi_timeout
  }
  rx_queue_settings {
    nr_count  = 1
    ring_size = length(
        regexall("(FCNVMeTarget|Target)", coalesce(var.adapter_template, "EMPTY"))
      ) > 0 ? 2048 : var.receive_ring_size
  }
  scsi_queue_settings {
    nr_count  = length(
        regexall("(FCNVMeTarget|FCNVMeInitiator)", coalesce(var.adapter_template, "EMPTY"))
      ) > 0 ? 16 : var.scsi_io_queue_count
    ring_size = var.scsi_io_ring_size
  }
  tx_queue_settings {
    nr_count  = 1
    ring_size = var.transmit_ring_size
  }
  dynamic "tags" {
    for_each = var.tags
    content {
      key   = tags.value.key
      value = tags.value.value
    }
  }
}
