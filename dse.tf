resource "oci_core_instance" "dse" {
  display_name        = "dse-${count.index}"
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.availability_domains.availability_domains[0]["name"]
  shape               = var.dse["shape"]

  source_details {
    source_id   = var.images[var.region]
    source_type = "image"
  }

  create_vnic_details {
    subnet_id      = oci_core_subnet.subnet.id
    hostname_label = "dse-${count.index}"
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(
      join(
        "\n",
        [
          "#!/usr/bin/env bash",
          "password=${var.dse["password"]}",
          file("./scripts/dse.sh"),
        ],
      ),
    )
  }

  freeform_tags = {
    "quick-start" = "{\"Deployment\":\"TF\", \"Publisher\":\"DataStax\", \"Offer\":\"dse\",\"Licence\":\"byol\"}"
  }

  count = var.dse["node_count"]
}