module "organization" {
  source = "./modules/organization"

  providers = {
    aws = aws.target
  }
}

module "guardrails" {
  source               = "./modules/guardrails"
  controls             = var.controls
  controls_with_params = var.controls_with_params
  ous_id_to_arn_map    = module.organization.ous_id_to_arn_map

  providers = {
    aws = aws.target
  }
}

