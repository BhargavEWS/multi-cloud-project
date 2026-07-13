# One-time GCP bootstrap (run in Cloud Shell)

These steps only need to run once per GCP project, before the first GitHub Actions
run. They create the things that Terraform itself can't create for you — the
state bucket Terraform reads its backend config from, and the identity GitHub
Actions uses to authenticate (keyless, via Workload Identity Federation — no
service-account JSON key ever leaves Google).

Open https://console.cloud.google.com, pick your free-trial project, click the
Cloud Shell icon (top right), and run the following, substituting your own
values for the four variables at the top.

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export GITHUB_REPO="Sowmyak12/multi-cloud-project"   # owner/repo
export STATE_BUCKET="${PROJECT_ID}-tfstate"

gcloud config set project "$PROJECT_ID"

# 1. Enable the APIs Terraform and the bootstrap steps below need.
gcloud services enable \
  container.googleapis.com \
  compute.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com

# 2. GCS bucket for Terraform remote state.
gcloud storage buckets create "gs://${STATE_BUCKET}" \
  --location="$REGION" --uniform-bucket-level-access
gcloud storage buckets update "gs://${STATE_BUCKET}" --versioning

# 3. Deploy service account that GitHub Actions will impersonate.
gcloud iam service-accounts create gha-deployer \
  --display-name="GitHub Actions deployer"

export SA_EMAIL="gha-deployer@${PROJECT_ID}.iam.gserviceaccount.com"

for ROLE in roles/container.admin roles/artifactregistry.admin \
            roles/compute.networkAdmin roles/iam.serviceAccountUser \
            roles/storage.admin roles/serviceusage.serviceUsageAdmin; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" --role="$ROLE"
done

# 4. Workload Identity Federation pool + provider, scoped to this GitHub repo only.
gcloud iam workload-identity-pools create "github-pool" \
  --location="global" --display-name="GitHub Actions pool"

gcloud iam workload-identity-pools providers create-oidc "github-provider" \
  --location="global" --workload-identity-pool="github-pool" \
  --display-name="GitHub OIDC provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='${GITHUB_REPO}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
export WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/providers/github-provider"

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/github-pool/attribute.repository/${GITHUB_REPO}"

# 5. Print the values you need to add as GitHub Actions repo secrets.
echo "GCP_PROJECT_ID   = ${PROJECT_ID}"
echo "GCP_REGION       = ${REGION}"
echo "GCP_STATE_BUCKET = ${STATE_BUCKET}"
echo "WIF_PROVIDER     = ${WIF_PROVIDER}"
echo "WIF_SA_EMAIL     = ${SA_EMAIL}"
```

## Add these as GitHub repo secrets
GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret:

| Secret name        | Value (from the output above)         |
|---------------------|----------------------------------------|
| `GCP_PROJECT_ID`    | `$PROJECT_ID`                          |
| `GCP_REGION`        | `$REGION`                              |
| `GCP_STATE_BUCKET`  | `$STATE_BUCKET`                        |
| `WIF_PROVIDER`      | `$WIF_PROVIDER`                        |
| `WIF_SA_EMAIL`      | `$SA_EMAIL`                            |

Once these five secrets exist, pushing to `main` (or manually running the
`terraform-gcp` workflow) drives everything else automatically.

## Optional: enable the FinOps budget alert
The deploy SA above deliberately does **not** get billing-admin rights (broad,
rarely-needed permission). To turn on the `google_billing_budget` resource in
`infra/gcp/budget.tf`, grant your *own* user account (not the deploy SA)
`roles/billing.costsManager` on the billing account, set
`enable_budget_alert = true` and `billing_account_id` in a `terraform.tfvars`,
and apply locally from Cloud Shell once.

## Tearing down
To stop consuming free-trial credit after you've captured screenshots:
```bash
cd infra/gcp
terraform destroy
```
Everything is defined as code, so recreating it later is a single `terraform apply` away.
