// Module: guardrails

locals {
  normalized = concat(
    [ for g in var.controls : {
        control_names = [ for control in g.control_names : { (control) = {} } ]
        organizational_unit_ids = g.organizational_unit_ids
      }
    ],
    var.controls_with_params
  )

  guardrail_entries = flatten([
    for grp in local.normalized : [
      for ctl in grp.control_names : [
        for ou in grp.organizational_unit_ids : {
          control_id = keys(ctl)[0]
          ou_id      = ou
          parameters = try(
            {
              for k, v in values(ctl)[0].parameters :
              k => v
              if length(v) > 0
            },
            null
          )
        }
      ]
    ]
  ])
}

resource "aws_controltower_control" "guardrails" {
  for_each = { for e in local.guardrail_entries : "${e.control_id}:${e.ou_id}" => e }

  control_identifier = "arn:aws:controlcatalog:::control/${each.value.control_id}"
  target_identifier  = var.ous_id_to_arn_map[each.value.ou_id]

  dynamic "parameters" {
    for_each = each.value.parameters != null ? each.value.parameters : {}
    content {
      key   = parameters.key
      value = jsonencode(parameters.value)
    }
  }
}