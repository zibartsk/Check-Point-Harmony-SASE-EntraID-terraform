terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

# Get well known MS applications info from hashicorp datasource
data "azuread_application_published_app_ids" "well_known" {}

resource "azuread_service_principal" "msgraph" {
  client_id    = data.azuread_application_published_app_ids.well_known.result.MicrosoftGraph
  use_existing = true
}


# Create App registration
resource "azuread_application" "app_registration" {
  # This will appear in the Azure portal under 'App registrations'.
  display_name = "${var.application_name}"

  # Specifies if the application is multi-tenant or single-tenant.
  # "AzureADMyOrg" for single-tenant (default), "AzureADMultipleOrgs" for multi-tenant.
  sign_in_audience = "AzureADMyOrg"
 
  # These are the URLs where authentication responses can be sent.
  # For web applications, this would be your application's redirect URI.
  web {
    redirect_uris = [
      "https://${var.workspace_name}.${var.sase_residency}/",
      "https://auth.${var.sase_residency}/login/callback"
    ]
    logout_url = "https://${var.workspace_name}.${var.sase_residency}"
  }

  
  # Define API permissions requested by the application.
  required_resource_access {
    # Microsoft Graph API
    resource_app_id = azuread_service_principal.msgraph.client_id

    # Delegated Permissions (Permissions on behalf of the signed-in user)
    resource_access {
      # User.Read - Allows users to sign in to the app, and allows the app to read the profile of signed-in users.
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["User.Read"]
      type = "Scope"                                # 'Scope' indicates a delegated permission
    }

    resource_access {
      # Directory.Read.All - Allows the app to read data in your organization's directory, such as users, groups, and devices.
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["Directory.Read.All"]
      type = "Scope"
    }

    resource_access {
      # Directory.AccessAsUser.All - Allows the app to have the same access to information in your work or school directory as you do.
      id   = azuread_service_principal.msgraph.oauth2_permission_scope_ids["Directory.AccessAsUser.All"]
      type = "Scope"
    }

    # Application Permissions (Permissions that the application holds directly, without a signed-in user)
    resource_access {
      # Directory.Read.All - Allows the app to read data in your organization's directory, such as users, groups, and devices.
      id   = azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"]
      type = "Role"                                 # 'Role' indicates an application permission
    }
  }
}


# Create Entrprise Application
resource "azuread_service_principal" "enterprise_application" {
  # Link the service principal to the application registration created above.
  client_id = azuread_application.app_registration.client_id
  feature_tags {
    enterprise = true
  }
}

# Grant admin consent for the Directory.Read.All application permission
resource "azuread_app_role_assignment" "directory_read_all_admin_consent" {
  # The ID of the application permission (app role) being granted.
  # This corresponds to the Directory.Read.All application permission ID.
  # app_role_id = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
  app_role_id = azuread_service_principal.msgraph.app_role_ids["Directory.Read.All"]

  # The object ID of the service principal (enterprise application) that is receiving the permission.
  principal_object_id = azuread_service_principal.enterprise_application.object_id

  # The object ID of the resource service principal (the API) to which the permission is being granted.
  # In this case, it's the Microsoft Graph API.
  resource_object_id = azuread_service_principal.msgraph.object_id
}


# Grant admin consent for multiple delegated permissions (User.Read, Directory.Read.All, Directory.AccessAsUser.All)
resource "azuread_service_principal_delegated_permission_grant" "all_delegated_admin_consent" {
  # The object ID of the service principal (enterprise application) that is receiving the permission.
  service_principal_object_id = azuread_service_principal.enterprise_application.object_id
  
  # The object ID of the resource service principal (the API) to which the permission is being granted.
  resource_service_principal_object_id = azuread_service_principal.msgraph.object_id
  
  # A list of delegated permission claim values
  claim_values = ["User.Read", "Directory.Read.All", "Directory.AccessAsUser.All"]
}


# Creates a client secret (password) for the application registration.
# This secret can be used by the application to authenticate to Azure AD.
resource "azuread_application_password" "app_secret" {
  # Link the secret to the application registration.
  application_id = azuread_application.app_registration.id

  # A descriptive name for the secret (optional).
  display_name = "SASEApplicationClientSecret"

  # The end date of the secret's validity.
  # Using a date 1 year from now. You can adjust this as needed.
  end_date = timeadd(timestamp(), "${var.app_registration_client_secret_duration}h") # 8760 hours = 1 year
}


# Data source to look up the specific user by their User Principal Name (UPN)
data "azuread_user" "assigned_users" {
  for_each = toset(var.sase_users)
  user_principal_name = each.value
}

# Assign multiple users to the enterprise application (default access role)
resource "azuread_app_role_assignment" "assign_multiple_users" {
  # Use a for_each loop to create an assignment for each user found
  for_each = data.azuread_user.assigned_users

  # The object ID of the user being assigned.
  principal_object_id = each.value.object_id

  # The object ID of the enterprise application (service principal) to which the user is being assigned.
  resource_object_id = azuread_service_principal.enterprise_application.object_id

  # When assigning to the default access role, use the well-known ID for the default user role.
  # This ID is '00000000-0000-0000-0000-000000000000' if no custom app roles are defined.
  app_role_id = "00000000-0000-0000-0000-000000000000"
}


# Data source to look up groups by their display names
data "azuread_group" "assigned_groups" {
  for_each     = toset(var.sase_groups)
  display_name = each.value
  # It's good practice to also specify security_enabled = true if you're sure they are security groups,
  # or omit it if they might be M365 groups.
  # security_enabled = true
}

# Assign multiple groups to the enterprise application (default access role)
resource "azuread_app_role_assignment" "assign_multiple_groups" {
  # Use a for_each loop to create an assignment for each group found
  for_each = data.azuread_group.assigned_groups

  # The object ID of the group being assigned.
  principal_object_id = each.value.object_id

  # The object ID of the enterprise application (service principal) to which the group is being assigned.
  resource_object_id = azuread_service_principal.enterprise_application.object_id

  # When assigning to the default access role, use the well-known ID for the default user role.
  # This ID is '00000000-0000-0000-0000-000000000000' if no custom app roles are defined.
  app_role_id = "00000000-0000-0000-0000-000000000000"
}

# Output the Application (Client) ID and Object ID
output "application_client_id" {
  description = "The Application (client) ID of the Azure AD Application."
  value       = azuread_application.app_registration.client_id
}

output "application_object_id" {
  description = "The Object ID of the Azure AD Application."
  value       = azuread_application.app_registration.object_id
}

# Output the generated client secret value.
# IMPORTANT: Treat this output as sensitive data and handle it securely.
# Use:
# terraform output -raw client_secret_value
# to retrieve
output "client_secret_value" {
  description = "The value of the generated client secret. Treat as sensitive!"
  value       = azuread_application_password.app_secret.value
  sensitive   = true # Mark as sensitive to prevent it from being shown in plain text in Terraform logs
}
