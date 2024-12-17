# Terraform Simple Chat Stack

Deploy OpenWebUI & LiteLLM to GKE and set a subdomain in Cloudflare.

## Prerequisites

### Terraform

```bash
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```
_[ref](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)_

### Google Cloud CLI (`gcloud`)

#### Install `gcloud` CLI

CLI is needed to authenticate and interact with Google Cloud.

```bash
brew install --cask google-cloud-sdk
```
_[or follow the official instructions](https://cloud.google.com/sdk/docs/install#installation_instructions)_

#### Login

```bash
gcloud init
```

### Cloudflare

#### API Token
- Navigate to [User API Tokens](https://dash.cloudflare.com/profile/api-tokens) or **Manage Account > Account API Tokens**.
- Create a new API Token with the permissions `Zone.DNS:Edit` (Limit permissing to just the zone _(a.k.a website/domain)_ you want to manage is recommended.)

#### Zone ID
- Navigate to the domain you want to manage.
- The Zone ID is in the right sidebar under **API**.


## Usage

### Supply Variables

Create a `terraform.tfvars` file with the following variables:

| Variable Name            | Description                                                  | Example Value           |
|--------------------------|--------------------------------------------------------------|-------------------------|
| `project_id`             | The GCP project ID                                           | `your-gcp-project-id`   |
| `region`                 | The GCP region                                               | `asia-southeast1`       |
| `zone`                   | The GCP zone                                                 | `asia-southeast1-a`     |
| `cluster_name`           | The name of the GKE cluster                                  | `chat-stack`            |
| `machine_type`           | The machine type for the node pool instances                 | `e2-standard-2`         |
| `openwebui_replicas`     | The number of replicas for the OpenWebUI deployment          | `2`                     |
| `domain`                 | Domain name to manage DNS records                            | `example.com`           |
| `subdomain`              | A subdomain to be used for the OpenWebUI                     | `webui`                 |
| `openai_api_key`         | The OpenAI API key                                           | `sk-xxxxxxxxxxxxxxxxx`  |
| `webui_name`             | The name displayed on the OpenWebUI                          | `Chat WebUI`            |
| `cloudflare_api_token`   | Cloudflare API token to manage DNS records                   | `your-cloudflare-token` |
| `cloudflare_zone_id`     | Cloudflare Zone ID (Not the domain name)                     | `0123467890abcdef01234` |

Example:
```hcl
project_id = "your-gcp-project-id"
region = "asia-southeast1"
zone = "asia-southeast1-a"
cluster_name = "chat-stack"
machine_type = "e2-standard-2"
openwebui_replicas = 2
domain = "example.com"
subdomain = "webui"
openai_api_key = "sk-xxxxxxxxxxxxxxxxx"
webui_name = "Chat WebUI"
cloudflare_api_token = "your-cloudflare-token"
cloudflare_zone_id = "your-zone-id"
```

### Initialize

```bash
terraform init
```

### Plan

Verify conditions before deployment

```bash
terraform plan
```

### Apply

```bash
terraform apply -auto-approve
```

### Destroy

```bash
terraform destroy -auto-approve
```
