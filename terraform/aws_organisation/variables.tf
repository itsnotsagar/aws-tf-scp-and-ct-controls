variable "policies_directory" {
  type    = string
  default = null
}

variable "policy_type" {
  type    = string
  default = "SERVICE_CONTROL_POLICY"
  validation {
    condition = contains([
      "AISERVICES_OPT_OUT_POLICY",
      "BACKUP_POLICY",
      "RESOURCE_CONTROL_POLICY",
      "SERVICE_CONTROL_POLICY",
      "TAG_POLICY"
    ], var.policy_type)
    error_message = "unsupported policy type"
  }
}

variable "description" {
  description = "Common description for all Service Control Policies"
  type        = string
  default     = "Terraform Managed Policy - DON'T MAKE CHANGES MANUALLY"
}

# Defining Region
variable "aws_region" {
  default = "eu-west-1"
}

# Defining Account Id
variable "account_id" {
  type = string
  default = "012345678910" #AWS Org Management Account ID
}

