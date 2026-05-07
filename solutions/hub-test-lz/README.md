# Hub Test Landing Zone (Terraform)

This solution deploys a minimal **test hub** baseline with:

- One resource group
- One hub virtual network
- A configurable list of private DNS zones

## Files

- `main.tf`: Resource group, hub vnet, and private DNS zones
- `variables.tf`: Input variables and validations
- `outputs.tf`: Resource IDs and created DNS zone names
- `terraform.tfvars.example`: Example values

## Usage

1. Copy the sample variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

2. Initialize Terraform:

```bash
terraform init
```

3. Review the plan:

```bash
terraform plan
```

4. Apply:

```bash
terraform apply
```

## Notes

- Private DNS zones are created in the same hub resource group.
- This solution intentionally does not create private DNS zone links to VNets, DNS resolver resources, or firewall resources. It is meant to be a lightweight test baseline.
