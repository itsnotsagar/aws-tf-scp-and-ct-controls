variable "controls" {

  type = list(object({
    control_names           = list(string)
    organizational_unit_ids = list(string)
  }))

  default     = []
  description = "Configuration of AWS Control Tower Controls (sometimes called Guardrails) without parameters and tags"
}

variable "controls_with_params" {
  type = list(
    object({
      control_names = list(map(object({
        parameters = optional(map(list(string)))
      })))
      organizational_unit_ids = list(string)
    })
  )

  default     = []
  description = "Configuration of AWS Control Tower Controls (sometimes called Guardrails) with parameters"
}

# Defining Region
variable "aws_region" {
  default = "eu-west-1"
}

# Defining Account Id
variable "account_id" {
  type = string
  default = "973642793185" #master account
}