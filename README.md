# AI Landing Zone Terraform

This repository contains Terraform code to deploy the Azure AI Landing Zone, leveraging (Azure Verified Modules)[https://aka.ms/avm] (AVM).
Since the AI Landing Zone uses several Private Endpoints, this repository also provides the Azure Policy code that automates the creation of A-records in the corresponding Private DNS Zones.

## Quick Start

- AI Landing Zone: Check the instructions at [AI Landing Zone Module Test](./ai/README.md)
- Azure Policy for AI Landing Zone: Check the instructions at [Azure Policy Module Test](./policies/README.md)
