# tf-aws-scp

## Add your files

- [ ] [Create](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#create-a-file) or [upload](https://docs.gitlab.com/ee/user/project/repository/web_editor.html#upload-a-file) files
- [ ] [Add files using the command line](https://docs.gitlab.com/ee/gitlab-basics/add-file.html#add-a-file-using-the-command-line) or push an existing Git repository with the following command:

```
cd existing_repo
git remote add origin https://gitlab.rnd.nxp.com/ccoet/gitlab-poc/aws-tf-scp.git
git branch -M main
git push -uf origin main
```

## Guardrails/SCP

Control Tower only allows enabling/disabling pre-defined controls (preventive controls – SCP) which can’t be modified.
[AWS Documentation - Control Tower](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-and-manage-aws-control-tower-controls-by-using-terraform.html)

CfCT can be deployed on top of Control Tower to give SCP customization functionality, but it relies on CodeCommit, CodePipeline and CodeBuild, services we are trying to move away from.
[AWS Documentation - CfCT](https://docs.aws.amazon.com/controltower/latest/userguide/cfcn-set-up-custom-scps.html)

For Deploying custom SCPs we will be making use of AWS organisation terraform modules and for enabling AWS Control Tower's control we will be making use of AWS Control Tower terraform modules.

## Control Tower Controls

For enabling AWS Control Tower's control navigate to `control_tower/variables.tfvars` directory

```
controls = [
    {
        control_names = [
            "503uicglhjkokaajywfpt6ros", # AWS-GR_ENCRYPTED_VOLUMES
            ...
        ],
        organizational_unit_ids = ["ou-1111-11111111", "ou-2222-22222222"...],
    },
    {
        control_names = [
            "50z1ot237wl8u1lv5ufau6qqo", # AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED
            ...
        ],
        organizational_unit_ids = ["ou-1111-11111111"...],
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
  },
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
    organizational_unit_ids = ["ou-2222-22222222"...],
  }
]
```

Keep in mind that controls can only be applied to OUs and not the root OU directly.

Control Tower's individual preventive controls don't create separate SCPs instead all the controls which are enabled for an OU are put in a single SCP as long as it has space left and then any other control after that will be put in the next SCP once the size is exhausted.

For getting the control_names/identifiers refer to [Controls Reference Guide](https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html).

AWS Control Tower doesn't allow making changes to the SCP as such but it does allow to make configuration changes to the SCP. For making configuration changes to the SCPs make use of controls_with_params list.

For checking which all controls support parameters, refer to [AWS - Parameterized Controls](https://docs.aws.amazon.com/controltower/latest/controlreference/control-parameter-concepts.html).

##### More on parameterized controls -

In AWS Control Tower, RCP-based and certain SCP-based controls support configuration. These controls contain elements that are included by AWS Control Tower conditionally, based on the configuration you select.

For example, some control policies include inline templating variables, such as the one shown in the example that follows. The example shows the ExemptedPrincipalArns parameter.

```
 {
            "Sid": "CTEC2PV1",
            "Effect": "Deny",
            "Action": [
                "ec2:CreateSnapshot",
                "ec2:CreateSnapshots"
            ],
            "Resource": "arn:*:ec2:*:*:volume/*",
            "Condition": {
                "Bool": {
                    "ec2:Encrypted": "false"
                }{% if ExemptedPrincipalArns %},
                "ArnNotLike": {
                    "aws:PrincipalArn": {{ExemptedPrincipalArns}}
                }{% endif %}
            }
        }
```


A control may support any of the following four configuration parameters:

- ExemptedPrincipalArns: A list of AWS IAM principal ARNs that are exempted from this control.

  - This parameter allows you to exempt IAM Principals from this control by way of an ArnNotLikeIfExists condition key operator and aws:PrincipalArn condition key that is applied to the control policy by AWS Control Tower when you enable the control. The ExemptedPrincipalArns parameter allows you to use the wildcard character (*) in the IAM principal ARNs that you specify. You can use the wildcard character to exempt all IAM principals in an AWS account, or exempt a common principal across multiple AWS accounts.

  - When you use the wildcard character to exempt principals, be sure that you follow the principal of least privilege: include only those IAM principal ARNs that you require to be exempt from a control. Otherwise, if your exemptions are too broad, the control may not come into effect when you intend it to.

- AllowedRegions: List of AWS Regions exempted from the control.

- ExemptedActions: List of AWS IAM actions exempted from the control.

- ExemptedResourceArns: List of resource ARNs exempted from the control.

## Custom SCPs

For deploying custom SCPs navigate to `aws_organization/scp_config.tf` directory

Put the SCP json in the `service_control_policy` folder and give it a name, this name will be taken as the name for SCPs without the `.json` extension.

`scp_config.tf` contains the configuration for deploying the SCP

```
locals {
  ou_map = {
    "r-wkup"       = ["root"]
    #"ou-example-1" = ["root", "scp1"]
    // You can add or remove entries here as needed
  }
}
```

Put the OU ID and the names of the SCPs that you want to attach to that OU (without the .json extension) in the ou_map dictionary

`"ou-example-1" = ["root", "scp1"]`

Only 5 SCPs in total can be attached to an OU

## Gitlab pipeline

The gitlab pipeline contains two stages (plan and apply)
```
stages:
  - terraform-plan
  - terraform-apply
```

Custom SCP has its own terraform plan and apply (aws_organization folder)
```
terraform-plan-aws-org:
  stage: terraform-plan
  tags:
    - optimized-test-org
  script:
    - cd terraform/aws_organization
    - terraform init
    - terraform plan -out=tfplan
  artifacts:
    paths:
      - terraform/aws_organization/tfplan
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "main"
      changes:
        - terraform/aws_organization/**

terraform-apply-aws-org:
  stage: terraform-apply
  tags:
    - optimized-test-org
  needs:
    - job: terraform-plan-aws-org
      optional: true
      artifacts: true
  script:
    - cd terraform/aws_organization
    - terraform init
    - terraform apply -auto-approve
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - terraform/aws_organization/**/*
```

Control Tower builtin SCP has its own terraform plan and apply (control_tower folder)
```
terraform-plan-control-tower:
  stage: terraform-plan
  tags:
    - optimized-test-org
  script:
    - cd terraform/control_tower
    - terraform init
    - terraform plan -var-file="variables.tfvars" -out=tfplan
  artifacts:
    paths:
      - terraform/control_tower/tfplan
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event" && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "main"
      changes:
        - terraform/control_tower/**

terraform-apply-control-tower:
  stage: terraform-apply
  tags:
    - optimized-test-org
  needs:
    - job: terraform-plan-control-tower
      optional: true
      artifacts: true
  script:
    - cd terraform/control_tower
    - terraform init
    - terraform apply -var-file="variables.tfvars" -auto-approve
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      changes:
        - terraform/control_tower/**/*
```