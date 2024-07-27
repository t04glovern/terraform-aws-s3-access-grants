variable "issuer_url" {
  description = "The URL of the OIDC issuer to use when federating access to S3 Access Grants."
  type        = string
  default     = "https://oauth.id.jumpcloud.com/"
}
