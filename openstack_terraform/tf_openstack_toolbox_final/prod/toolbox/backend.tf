terraform {
  backend "gcs" {
    bucket  = "tf-openstack-cloud-prod"
  }
}
