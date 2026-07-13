# AWS mirror (EKS) — apply-ready, not deployed

This module is the AWS twin of `infra/gcp`: same app, same GitOps model, on an
EKS cluster instead of GKE Autopilot. It's kept apply-ready but **not deployed**
so the live portfolio demo doesn't run (and bill) on two clouds at once.

Uses the community `terraform-aws-modules/vpc` and `terraform-aws-modules/eks`
modules (the standard, production-grade way to stand these up on AWS) rather
than hand-rolling VPC/EKS resources.

To actually deploy it once you have an AWS account:

```bash
cd infra/aws
cp terraform.tfvars.example terraform.tfvars   # edit as needed
terraform init                                  # add an S3 backend block first, see versions.tf
terraform apply
```

Cost-conscious choices already baked in: a single NAT gateway instead of one
per AZ, SPOT capacity for the node group, and a small default instance type.
Mirrors the GCP side's Artifact Registry with an ECR repo (`taskflow`,
scan-on-push enabled) and the same `Environment`/`CostCenter` tagging scheme
for FinOps governance across both clouds.
