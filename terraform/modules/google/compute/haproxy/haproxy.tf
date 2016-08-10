#--------------------------------------------------------------
# This module creates all resources necessary for HAProxy
#--------------------------------------------------------------

variable "name"              { }
variable "zone" {}
variable "atlas_username"    { }
variable "atlas_environment" { }
variable "atlas_token"       { }
variable "subnetwork"              { }
variable "image" {}
variable "nodes"             { }
variable "instance_type"     { }

resource "template_file" "haproxy_config" {
  template = "${path.module}/haproxy.sh.tpl"
  count    = "${var.nodes}"

  lifecycle { create_before_destroy = true }

  vars {
    atlas_username    = "${var.atlas_username}"
    atlas_environment = "${var.atlas_environment}"
    atlas_token       = "${var.atlas_token}"
    node_name         = "${var.name}-${count.index}"
  }
}

resource "google_compute_instance" "haproxy" {
  name         = "${var.name}-${count.index}"
  count        = "${var.nodes}"
  machine_type = "${var.instance_type}"
  zone         = "${var.zone}"

  metadata_startup_script = "${element(template_file.haproxy_config.*.rendered, count.index)}"

  disk {
    image = "${var.image}"
  }

  network_interface {
    subnetwork = "${var.subnetwork}"

    access_config {
      # ephemeral
    }
  }
}

output "private_ips" {
  value = "${join(",", google_compute_instance.haproxy.*.network_interface.0.address)}"
}