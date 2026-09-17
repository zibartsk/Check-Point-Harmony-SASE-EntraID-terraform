# Check Point SASE & Entra ID (Azure AD) IdP Integration with Terraform

This Terraform configuration is designed to significantly **streamline the integration of Microsoft Entra ID (formerly Azure AD) as an Identity Provider (IdP) with Check Point Harmony SASE**. It automates the key steps described in the official Check Point SASE admin guide, helping you save valuable time.

---

## Important: SCIM provisioning

Terraform creates the Entra ID application, permissions, client secret, and user/group assignments. Check Point SCIM provisioning must then be enabled in the SASE portal because the SCIM token is generated there.

After `terraform apply`:

1. In Check Point SASE, go to **Settings > Identity Providers**, add **Microsoft Azure AD**, and enter the tenant domain, the Terraform `application_client_id`, and the sensitive `client_secret_value` output.
2. Enable **SCIM Integration**, save the provider, open its settings, and click **Generate Token**. Copy the generated token.
3. In Entra ID, open the enterprise application, choose **Provision User Accounts**, select **Bearer authentication**, and use the `scim_endpoint` output as the tenant URL and the generated token as the secret token.
4. Enable provisioning for users and groups. Set `userName` from `mail` with precedence 2; set `emails[type eq "work"].value` from `userPrincipalName` with matching precedence 3; add `objectId` to `nickName` with matching precedence 1 and apply it only during object creation.
5. Retain the Check Point mappings for `nickName`, `emails[type eq "work"].value`, `userName`, `active`, `name.givenName`, and `name.familyName`; remove other mappings, assign the required users/groups, and start provisioning.

The SCIM endpoint is also available with `terraform output scim_endpoint`.

---

## 📚 Reference Documentation

This automation essentially covers the steps outlined in the official Check Point SASE Admin Guide:

[Microsoft Entra ID SCIM integration - Check Point SASE Admin Guide](https://sc1.checkpoint.com/documents/Infinity_Portal/WebAdminGuides/EN/SASE-Admin-Guide/SASE_Security/Topics/microsoftentraid_scim/microsoft_entra_id_scim_integration_overview.html)

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
