variable "sase_residency" {
  description = "SASE residency US / EU / IN /AU"
  type        = string
  default     = "eu.sase.checkpoint.com"  # US: perimeter81.com; India: in.sase.checkpoint.com; Australia: au.sase.checkpoint.com
}

variable "workspace_name" {
  description = "SASE workspace name"
  type        = string
}

variable "application_name" {
  description = "SASE application name in EntraID"
  type        = string
  default     = "CheckPoint-SASE"
}

variable "sase_users" {
  description = "A list of User Principal Names (UPNs) to assign to the enterprise application."
  type        = list(string)
  default     = [] # Provide an empty list as a default, or remove if you always want to define it.
}

variable "app_registration_client_secret_duration" {
  description = "The duration in hours for the client secret's validity (e.g., 8760 for 1 year, 4380 for 6 months)."
  type        = number
  default     = 8760 # Default to 1 year (8760 hours)
}

variable "sase_groups" {
  description = "A list of Azure AD group display names to assign to the SASE enterprise application."
  type        = list(string)
  default     = [] # Provide an empty list as a default, or make it required.
}