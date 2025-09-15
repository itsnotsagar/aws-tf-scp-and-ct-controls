output "ous_id_to_arn_map" {
  value       = module.organization.ous_id_to_arn_map
  description = "Map from OU id to OU arn for the whole organization"
}