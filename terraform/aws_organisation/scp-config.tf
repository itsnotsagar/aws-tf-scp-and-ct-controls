locals {
  ou_map = {
    "r-wkup"           = ["root"],
    "ou-wkup-o3h1m8yn" = ["staging-ou"]
    #"ou-example-1" = ["root", "scp1"]
    // You can add or remove entries here as needed
  }
}

locals {
  policies_directory = var.policies_directory == null ? lower(var.policy_type) : var.policies_directory
}
