variable "controls" {
  type = list(object({
    control_names           = list(string)
    organizational_unit_ids = list(string)
  }))
  description = "Controls without parameters"
}

variable "controls_with_params" {
  type = list(object({
    control_names           = list(map(object({ parameters = optional(map(list(string))) })) )
    organizational_unit_ids = list(string)
  }))
  description = "Controls with parameters"
}

variable "ous_id_to_arn_map" {
  type        = map(string)
  description = "Map of OU IDs to ARN from organization module"
}