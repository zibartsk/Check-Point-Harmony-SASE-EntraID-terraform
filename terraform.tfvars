sase_residency     = "eu.sase.checkpoint.com"   # |---workspace_name----|----sase_residency---|
workspace_name     = "kaspars-demo-workspace"   # kaspars-demo-workspace.eu.sase.checkpoint.com
application_name   = "CheckPoint-SASE"          # Enterprise application and App registration name in EntraID
app_registration_client_secret_duration = 8760  # Example: 1 year (8760 hours) or for 6 months: 4380 or for 2 years: 17520

sase_users = [
  "PradeepG@6dz22b.onmicrosoft.com",
  "kzadmin@6dz22b.onmicrosoft.com",
  # Add more UPNs as needed
]

sase_groups = [
  "SASE_Users"
  # Add more group display names as needed
]