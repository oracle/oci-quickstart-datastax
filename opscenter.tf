resource "oci_core_instance" "opscenter" {
  display_name        = "opscenter"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0]["name"]
  shape               = "VM.Standard2.4"

  source_details {
    source_id   = var.images[var.region]
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.subnet.id
    hostname_label = "opscenter"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "username=${var.dse["username"]}",
          "password=${var.dse["password"]}",
          "node_count=${var.dse["node_count"]}",
          "version=${var.dse["version"]}",
          "echo ${base64encode(var.ssh_private_key)} | base64 -d > ~/.ssh/oci",
          file("./scripts/opscenter.sh"),
        ],
      ),
    )
  }

  freeform_tags = {
    "quick-start" = "{\"Deployment\":\"TF\", \"Publisher\":\"DataStax\", \"Offer\":\"dse\",\"Licence\":\"byol\"}"
  }
}

data "oci_core_vnic_attachments" "opscenter_vnic_attachments" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0]["name"]
  instance_id         = oci_core_instance.opscenter.*.id[0]
}

data "oci_core_vnic" "opscenter_vnic" {
  vnic_id = data.oci_core_vnic_attachments.opscenter_vnic_attachments.vnic_attachments[0]["vnic_id"]
}