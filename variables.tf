variable "sso_instance_id" {
  description = "The ID of the SSO instance to optionally use when federating access to S3 Access Grants."
  type        = string
  default     = ""
}

variable "sso_grantee" {
  description = "The type and ID (Group or User) of the grantee to use when federating access to S3 Access Grants."
  type        = map(string)
  default     = {
    type = "IAM"
    id   = ""
  }

  validation {
    condition     = can(regex("^(DIRECTORY_USER|DIRECTORY_GROUP|IAM)$", var.sso_grantee.type))
    error_message = "The value of sso_grantee.type must be one of DIRECTORY_USER, DIRECTORY_GROUP, or IAM."
  }

  validation {
    condition     = var.sso_grantee.type != "IAM" && length(var.sso_grantee.id) > 0 || var.sso_grantee.type == "IAM" && length(var.sso_grantee.id) == 0
    error_message = "The value of sso_grantee.id must be set when sso_grantee.type is DIRECTORY_USER or DIRECTORY_GROUP."
  }
}