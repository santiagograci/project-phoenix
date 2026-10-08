# 🚀 Project Phoenix: Enterprise IaaS Auto-Scaling & Zero-Downtime Architecture

[![Azure](https://img.shields.io/badge/Azure-Cloud_IaaS-0078D4?logo=microsoftazure&logoColor=white)](https://azure.microsoft.com/)
[![IaC](https://img.shields.io/badge/IaC-Bicep-00599C?logo=azuredevops&logoColor=white)](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions&logoColor=white)](https://github.com/features/actions)
[![Security](https://img.shields.io/badge/Security-Zero--Trust_%7C_KeyVault-critical?logo=azurekeyvault&logoColor=white)](https://azure.microsoft.com/)
[![FinOps](https://img.shields.io/badge/FinOps-Ephemeral_%26_Optimized-success?logo=cashapp&logoColor=white)](https://www.finops.org/)

---

## 📌 Executive Summary
**Project Phoenix** is an enterprise-grade Infrastructure-as-Code (IaC) implementation designed on **Microsoft Azure**. The project models an automated, fault-tolerant, and elastic IaaS topology engineered to handle production workloads with **Zero-Downtime (Blue-Green / Rolling Upgrades)**, strict **Zero-Trust network security**, and horizontal auto-scaling.

Entirely provisioned natively via **Azure Bicep** and enforced by automated governance policies (**Azure Policy**), it showcases true multi-tier enterprise architecture without relying on managed Kubernetes clusters, reflecting real-world financial and enterprise compliance demands.

---

## 🏛️ Architecture Overview

```mermaid
graph TD
    User([End Users / Web Clients]) -->|HTTPS Port 443 / 80| AppGW[Azure Application Gateway v2 <br/> WAF & L7 Load Balancer]

    subgraph Azure Cloud - rg-phoenix-prod-001 [Virtual Network: 10.0.0.0/16]

        subgraph snet-appgateway [Subnet Frontend: 10.0.1.0/24]
            AppGW
        end

        subgraph snet-backend-vmss [Subnet Backend: 10.0.2.0/24]
            subgraph VMSS [Virtual Machine Scale Sets - Linux]
                VM1[Instance 01 <br/> Rolling / Canary App]
                VM2[Instance 02 <br/> Auto-scaled Workload]
                VMn[Instance n ...]
            end
        end

        subgraph AzureBastionSubnet [Subnet Management: 10.0.3.0/24]
            Bastion[Azure Bastion Host <br/> Zero-Trust RDP/SSH Proxy]
        end
    end

    AppGW -->|Health Probes & Dynamic Routing| VMSS
    Bastion -.->|Secure Private Management| VMSS

    subgraph Security & State Management
        KeyVault[Azure Key Vault <br/> RBAC Enabled]
        Identity[User-Assigned Managed Identity]
        DB[(Managed SQL Database <br/> Private Endpoint)]
    end

    VMSS -.->|Tokenless Auth via Managed Identity| KeyVault
    VMSS -.->|Private Link Isolation| DB

    subgraph Automation & CI/CD
        GH[GitHub Actions Pipeline] -->|What-If & Bicep Deployment| ARM[Azure Resource Manager]
    end

    style AppGW fill:#0072C6,stroke:#fff,stroke-width:2px,color:#fff
    style VMSS fill:#107C10,stroke:#fff,stroke-width:2px,color:#fff
    style Bastion fill:#5C2D91,stroke:#fff,stroke-width:2px,color:#fff
    style KeyVault fill:#D83B01,stroke:#fff,stroke-width:2px,color:#fff
    style GH fill:#24292e,stroke:#fff,stroke-width:2px,color:#fff
```

---

## 🔑 Key Engineering Highlights

### 1. Zero-Trust Network Perimeter
* **No Public IPs on Workloads:** Backend virtual machines reside entirely in a private subnet (`10.0.2.0/24`) without direct internet access.
* **Azure Bastion:** Hardened administrative access via HTTPS tunneling, completely eliminating open management ports (22/3389) to the public internet.
* **Web Application Firewall (WAF v2):** Layer 7 deep inspection and automated DDoS mitigation at the ingress tier.

### 2. High Availability & Elasticity
* **Virtual Machine Scale Sets (VMSS):** Dynamic horizontal scaling based on metric telemetry (CPU consumption thresholds: Scale-out at >75%, Scale-in at <30%).
* **Health Probes & Rolling Upgrades:** Continuous health monitoring with automated instance draining, ensuring true zero-downtime during application deployments.

### 3. Identity-Driven Secret Management
* **Managed Identities (Zero Hardcoded Secrets):** VMs dynamically authenticate to **Azure Key Vault** using a User-Assigned Managed Identity with scoped RBAC roles (`Key Vault Secrets User`).
* **In-Memory Injection:** Secrets and connection strings are pulled at boot directly into memory.

### 4. FinOps & Ephemeral Infrastructure
* Automated lifecycle scripts enabling a **"Deploy-Verify-Teardown"** pipeline to maintain full environment test cycles under **$12 USD per run**.
* Strict enforcement of organizational tagging policies (`Environment`, `Owner`, `CostCenter`, `Project`) verified via pre-flight `what-if` checks.

---

## 📂 Repository Structure

```text
project-phoenix/
├── infrastructure/
│   ├── main.bicep                     # Master Orchestrator (Scopes, global parameters, outputs)
│   └── modules/
│       ├── network.bicep              # VNet, Subnets (AppGW, VMSS, Bastion), NSGs
│       ├── bastion.bicep              # Azure Bastion Host + Standard Public IP
│       ├── keyvault.bicep             # Key Vault (RBAC enabled) + Managed Identity + Role Assignment
│       ├── appgateway.bicep          # Application Gateway v2 (WAF, Probes, Listeners, Routing Rules)
│       └── vmss.bicep                 # VM Scale Sets + Autoscaling rules + Custom Script Extensions
├── .github/
│   └── workflows/
│       └── deploy.yml                 # Automated Validation, What-If, and Production Deployment
├── README.md                          # Architecture and project documentation
```

---

## 🚀 Deployment Instructions

### Prerequisites
* Azure CLI (v2.50+)
* Bicep CLI (`az bicep install`)

### 1. Pre-flight Validation (What-If)
```bash
az deployment group what-if \
  --resource-group rg-phoenix-prod-001 \
  --template-file infrastructure/main.bicep
```

### 2. Deploy Infrastructure
```bash
az deployment group create \
  --resource-group rg-phoenix-prod-001 \
  --template-file infrastructure/main.bicep
```

### 3. Teardown (FinOps Lifecycle)
To destroy all resources and prevent ongoing costs:
```bash
az group delete --name rg-phoenix-prod-001 --yes --no-wait
```

---

## 👨‍💻 Author
**Santiago Graciano**
*DevOps & Cloud Infrastructure Engineer*
