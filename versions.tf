terraform {
  required_version = ">= 1.5.0"

  required_providers {
    sg = {
      source  = "releases.stackgen.com/stackgen/stackgen"
      version = ">= 0.1.33, != 0.1.35, != 0.1.36, < 0.2.0"
    }
  }
}
