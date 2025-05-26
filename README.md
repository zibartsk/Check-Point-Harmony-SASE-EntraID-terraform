# Check Point SASE & Entra ID (Azure AD) IdP Integration with Terraform

This Terraform configuration is designed to significantly **streamline the integration of Microsoft Entra ID (formerly Azure AD) as an Identity Provider (IdP) with Check Point Harmony SASE**. It automates the key steps described in the official Check Point SASE admin guide, helping you save valuable time.

---

## ⚠️ Important Note

This Terraform currently **does not include the SCIM (System for Cross-domain Identity Management) part** of the integration. You will need to configure SCIM separately if required for user provisioning.

---

## 📚 Reference Documentation

This automation essentially covers the steps outlined in the official Check Point SASE Admin Guide:

[Microsoft Entra ID (formerly Azure AD) (App Registration) - Check Point SASE Admin Guide](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/SASE-Admin-Guide/Content/Topics-SASE-IdP/Azure_AD/AzureAD_AppReg.htm?tocpath=Settings%7CIdentity%20Providers%7CMicrosoft%20Entra%20ID%20(formerly%20Azure%20AD)%20(App%20Registration)%7C_____0#Microsoft_Entra_ID_(formerly_Azure_AD)_(App_Registration))

---

## ⚙️ Required Inputs

All necessary inputs for this Terraform configuration are conveniently collected within the `terraform.tfvars` file. Here's a breakdown of the variables and their purpose:

| Variable Name                               | Description                                                                                             | Example Value                         |
| :------------------------------------------ | :------------------------------------------------------------------------------------------------------ | :------------------------------------ |
| `sase_residency`                            | Your Check Point SASE data residency region. **Options:** `perimeter81.com` (US), `in.sase.checkpoint.com` (India), `au.sase.checkpoint.com` (Australia), `eu.sase.checkpoint.com` (EU). | `"eu.sase.checkpoint.com"`            |
| `workspace_name`                            | The name of your Check Point Harmony SASE workspace.                                                    | `"demo-workspace"`            |
| `application_name`                          | The desired name for both the Enterprise Application and the App Registration in Microsoft Entra ID.      | `"CheckPoint-SASE"`                   |
| `app_registration_client_secret_duration`   | The duration, in hours, for which the client secret for the Entra ID App Registration will be valid.    | `8760` (1 year)                       |
| `sase_users`                                | A list of User Principal Names (UPNs) from your Entra ID tenant to assign to the Enterprise Application. | See example below.                    |
| `sase_groups`                               | A list of group display names from your Entra ID tenant to assign to the Enterprise Application.        | See example below.                    |

**Example `terraform.tfvars` content:**

```terraform
sase_residency                    = "eu.sase.checkpoint.com"
workspace_name                    = "demo-workspace"
application_name                  = "CheckPoint-SASE"
app_registration_client_secret_duration = 8760 # Example: 1 year (8760 hours)
                                           # Common durations: 6 months (4380), 2 years (17520)

sase_users = [
  "PradeepG@idp.onmicrosoft.com",
  "LeeG@idp.onmicrosoft.com",
  # Add more UPNs as needed
]

sase_groups = [
  "SASE_Users"
  # Add more group display names as needed
]
