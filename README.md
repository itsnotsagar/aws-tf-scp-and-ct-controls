# AWS Terraform SCP and Control Tower Controls

A comprehensive Terraform solution for managing AWS Service Control Policies (SCPs) and AWS Control Tower controls across your AWS Organization. This project provides a unified approach to implement both custom SCPs and AWS Control Tower's built-in preventive controls.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Control Tower Controls](#control-tower-controls)
- [Custom SCPs](#custom-scps)
- [GitLab CI/CD Pipeline](#gitlab-cicd-pipeline)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## Overview

This repository contains Terraform modules and configurations to:

- Deploy and manage custom Service Control Policies (SCPs) across AWS Organizations
- Enable and configure AWS Control Tower preventive controls
- Automate deployment through GitLab CI/CD pipelines
- Provide granular control over AWS resource access and compliance

## Architecture

The solution is structured into two main components:

1. **Custom SCPs** (`terraform/aws_organization/`) - For deploying custom Service Control Policies
2. **Control Tower Controls** (`terraform/control_tower/`) - For enabling AWS Control Tower's built-in controls

### Why This Approach?

**Control Tower Limitations:**
- Control Tower only allows enabling/disabling pre-defined controls (preventive controls – SCP) which can't be modified
- [AWS Documentation - Control Tower](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/deploy-and-manage-aws-control-tower-controls-by-using-terraform.html)

**Alternative Solutions:**
- CfCT (Customizations for Control Tower) can be deployed on top of Control Tower for SCP customization, but relies on CodeCommit, CodePipeline and CodeBuild services
- [AWS Documentation - CfCT](https://docs.aws.amazon.com/controltower/latest/userguide/cfcn-set-up-custom-scps.html)

**Our Solution:**
- Custom SCPs: AWS Organization Terraform modules for complete customization
- Control Tower Controls: AWS Control Tower Terraform modules for built-in controls
- GitLab CI/CD: Modern pipeline approach avoiding legacy AWS services

## Prerequisites

Before using this solution, ensure you have:

- AWS Organization set up with appropriate permissions
- AWS Control Tower deployed (for Control Tower controls)
- Terraform >= 1.0 installed
- GitLab CI/CD runner with AWS credentials configured
- Appropriate IAM permissions for:
  - Managing AWS Organizations
  - Managing Service Control Policies
  - Managing Control Tower controls

### Required AWS Permissions

The deployment requires the following AWS permissions:
- `organizations:*`
- `controltower:*`
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `iam:CreatePolicy`

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd aws-tf-scp-and-ct-controls
   ```

2. **Configure your SCPs and Controls:**
   - For Control Tower controls: Edit `terraform/control_tower/variables.tfvars`
   - For custom SCPs: Add JSON policies to `terraform/aws_organization/service_control_policy/`

3. **Deploy via GitLab CI/CD:**
   - Create a merge request to trigger planning
   - Merge to main branch to apply changes

## Control Tower Controls

AWS Control Tower provides pre-built preventive controls that can be enabled across your organization.

### Configuration

Navigate to `terraform/control_tower/variables.tfvars` and configure your controls:

```hcl
# Basic controls without parameters
controls = [
    {
        control_names = [
            "503uicglhjkokaajywfpt6ros", # AWS-GR_ENCRYPTED_VOLUMES
            "50z1ot237wl8u1lv5ufau6qqo", # AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED
            "5g1xmq8lzwwxkqjd7g3k8nkxs", # AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP
        ],
        organizational_unit_ids = ["ou-1111-11111111", "ou-2222-22222222"],
    },
    {
        control_names = [
            "4g8m7q9n3p5r8s2t6v1w4x7z", # AWS-GR_S3_BUCKET_PUBLIC_ACCESS_PROHIBITED
        ],
        organizational_unit_ids = ["ou-3333-33333333"],
    }
]

# Controls with parameters (for advanced configuration)
controls_with_params = [
    {
        control_names = [
            {
                "9sqqct2tcfsnr10yl4f2av1mq" = { # CT.EC2.PV.6
                    parameters = {
                        "ExemptedPrincipalArns" : [
                            "arn:aws:iam::*:role/AdminRole",
                            "arn:aws:iam::123456789012:role/SpecificRole"
                        ]
                    }
                }
            }
        ],
        organizational_unit_ids = ["ou-1111-11111111"],
    }
]
```

### Important Notes

- **OU Restrictions:** Controls can only be applied to Organizational Units (OUs), not the root OU directly
- **SCP Consolidation:** Control Tower consolidates multiple controls into single SCPs when possible
- **Size Limits:** When SCP size limits are reached, additional controls create new SCPs

### Finding Control Identifiers

Use the [AWS Control Tower Controls Reference Guide](https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html) to find control identifiers.

### Parameterized Controls

Some controls support configuration parameters. For a complete list, see [AWS Parameterized Controls Documentation](https://docs.aws.amazon.com/controltower/latest/controlreference/control-parameter-concepts.html).

#### Supported Parameters

- **ExemptedPrincipalArns:** IAM principal ARNs exempt from the control
- **AllowedRegions:** AWS Regions exempt from the control  
- **ExemptedActions:** IAM actions exempt from the control
- **ExemptedResourceArns:** Resource ARNs exempt from the control

#### Parameter Example

```json
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

## Custom SCPs

Custom SCPs provide complete control over AWS resource access policies.

### Configuration

1. **Create SCP JSON files:**
   Place your SCP JSON files in `terraform/aws_organization/service_control_policy/`
   
   Example: `terraform/aws_organization/service_control_policy/deny-root-access.json`
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Sid": "DenyRootAccess",
               "Effect": "Deny",
               "Principal": {
                   "AWS": "*"
               },
               "Action": "*",
               "Resource": "*",
               "Condition": {
                   "StringEquals": {
                       "aws:PrincipalType": "Root"
                   }
               }
           }
       ]
   }
   ```

2. **Configure OU mappings:**
   Edit `terraform/aws_organization/scp-config.tf`:
   
   ```hcl
   locals {
       ou_map = {
           "r-wkup"           = ["root"]                    # Root OU with default policy
           "ou-1111-11111111" = ["root", "deny-root-access"] # Security OU with custom policy
           "ou-2222-22222222" = ["root", "restrict-regions", "deny-root-access"] # Multi-policy OU
       }
   }
   ```

### SCP Limitations

- Maximum 5 SCPs per OU
- Maximum SCP size: 5,120 characters
- SCP names are derived from JSON filenames (without .json extension)

### Example SCP Policies

#### Restrict AWS Regions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "RestrictRegions",
            "Effect": "Deny",
            "Action": "*",
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": [
                        "us-east-1",
                        "us-west-2",
                        "eu-west-1"
                    ]
                }
            }
        }
    ]
}
```

#### Prevent Root User Actions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PreventRootActions",
            "Effect": "Deny",
            "Action": [
                "iam:*",
                "organizations:*",
                "account:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalType": "Root"
                }
            }
        }
    ]
}
```

## GitLab CI/CD Pipeline

The pipeline provides automated planning and deployment with separate workflows for each component.

### Pipeline Structure

```yaml
stages:
  - terraform-plan
  - terraform-apply
```

### Pipeline Jobs

#### AWS Organization (Custom SCPs)
- **Plan:** `terraform-plan-aws-org`
- **Apply:** `terraform-apply-aws-org`
- **Trigger:** Changes to `terraform/aws_organization/**`

#### Control Tower Controls
- **Plan:** `terraform-plan-control-tower`  
- **Apply:** `terraform-apply-control-tower`
- **Trigger:** Changes to `terraform/control_tower/**`

### Pipeline Execution

1. **Merge Request:** Triggers planning jobs for changed components
2. **Main Branch:** Triggers apply jobs for changed components
3. **Artifacts:** Plan files are stored and passed to apply jobs

### Runner Requirements

Ensure your GitLab runners have:
- Terraform installed
- AWS CLI configured
- Appropriate AWS credentials
- Network access to AWS APIs

## Best Practices

### Security
- Use least privilege principles in SCP design
- Regularly review and audit applied policies
- Test SCPs in non-production environments first
- Use parameterized controls for flexibility

### Organization
- Use descriptive names for SCP JSON files
- Group related policies logically
- Document policy purposes and impacts
- Maintain version control for all changes

### Deployment
- Always review Terraform plans before applying
- Use merge requests for all changes
- Monitor AWS CloudTrail for policy violations
- Implement proper backup and rollback procedures

### Performance
- Minimize SCP complexity to reduce evaluation time
- Consolidate similar policies when possible
- Use specific resource ARNs instead of wildcards when feasible

## Troubleshooting

### Common Issues

#### SCP Size Exceeded
**Error:** Policy document exceeds maximum size
**Solution:** Split large policies into multiple smaller SCPs

#### Control Not Found
**Error:** Invalid control identifier
**Solution:** Verify control ID in [AWS Controls Reference](https://docs.aws.amazon.com/controltower/latest/controlreference/all-global-identifiers.html)

#### OU Not Found
**Error:** Organizational Unit does not exist
**Solution:** Verify OU ID in AWS Organizations console

#### Permission Denied
**Error:** Insufficient permissions to apply policy
**Solution:** Ensure runner has required AWS permissions

### Debugging Steps

1. **Check Terraform State:**
   ```bash
   terraform state list
   terraform state show <resource>
   ```

2. **Validate Configurations:**
   ```bash
   terraform validate
   terraform plan -detailed-exitcode
   ```

3. **Review AWS Logs:**
   - CloudTrail logs for API calls
   - Control Tower logs for control deployment
   - Organization logs for SCP changes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a merge request

### Development Guidelines

- Follow Terraform best practices
- Update documentation for any changes
- Test changes in development environment
- Use conventional commit messages

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For questions or issues:
- Create an issue in this repository
- Review AWS documentation for Control Tower and Organizations
- Consult Terraform AWS provider documentation

## References

- [AWS Control Tower Documentation](https://docs.aws.amazon.com/controltower/)
- [AWS Organizations Documentation](https://docs.aws.amazon.com/organizations/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Control Tower Controls Reference](https://docs.aws.amazon.com/controltower/latest/controlreference/)