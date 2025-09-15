controls = [
  {
    control_names = [
      "aqnqv7jjgi2dtl6r1v12xglio", # CT.STS.PV.1 (Require that the organization's AWS Security Token Service resources are accessible only by IAM principals that belong to the organization, or by an AWS service)
    ],
    organizational_unit_ids = [
      "ou-rlup-o3h112", # /dedicated-ou
      "ou-rlup-ku4y22"  # /test-ou
    ],
  }
]

controls_with_params = [
  {
    control_names = [
      {
        "9sqqct2tcfsnr10yl4f2av1mq" = { # CT.EC2.PV.6
          parameters = {
            "ExemptedPrincipalArns" : ["arn:aws:iam::*:role/RoleName"]
          }
        }
      }
    ],
    organizational_unit_ids = [],
  }
]
