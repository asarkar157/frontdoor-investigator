#!/usr/bin/env python3
"""Resolve a StackGen/Aiden workspace name to its UUID using read-only data sources."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


TF_MAIN = r'''
terraform {
  required_version = ">= 1.5"
  required_providers {
    sg = {
      source  = "releases.stackgen.com/stackgen/stackgen"
      version = ">= 0.1.33, != 0.1.35, != 0.1.36, < 0.2.0"
    }
  }
}

provider "sg" {
  stackgen_url   = var.stackgen_url
  stackgen_token = var.stackgen_token
}

variable "stackgen_url" {
  type = string
}

variable "stackgen_token" {
  type      = string
  sensitive = true
}

data "sg_me" "current" {}
data "sg_organizations" "all" {}

output "lookup" {
  value = {
    memberships   = data.sg_me.current.orgs
    organizations = data.sg_organizations.all.organizations
  }
}
'''


def run(command: list[str], cwd: Path, env: dict[str, str]) -> str:
    process = subprocess.run(
        command,
        cwd=str(cwd),
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if process.returncode != 0:
        sys.stderr.write(process.stderr)
        raise SystemExit(process.returncode)
    return process.stdout


def normalize(value: str) -> str:
    return " ".join(value.casefold().strip().split())


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--stackgen-url",
        default=os.environ.get("STACKGEN_URL") or os.environ.get("TF_VAR_stackgen_url"),
    )
    parser.add_argument(
        "--stackgen-token",
        default=os.environ.get("STACKGEN_TOKEN") or os.environ.get("TF_VAR_stackgen_token"),
    )
    parser.add_argument("--workspace-name", required=True)
    args = parser.parse_args()

    if not args.stackgen_url:
        parser.error("--stackgen-url or STACKGEN_URL is required")
    if not args.stackgen_token:
        parser.error("--stackgen-token or STACKGEN_TOKEN is required")

    terraform = shutil.which("tofu") or shutil.which("terraform")
    if not terraform:
        raise SystemExit("error: neither tofu nor terraform is on PATH")

    env = os.environ.copy()
    env["TF_VAR_stackgen_url"] = args.stackgen_url
    env["TF_VAR_stackgen_token"] = args.stackgen_token
    env.setdefault("TF_IN_AUTOMATION", "1")

    with tempfile.TemporaryDirectory(prefix="sg-workspace-lookup-") as temporary_directory:
        working_directory = Path(temporary_directory)
        (working_directory / "main.tf").write_text(TF_MAIN, encoding="utf-8")
        run([terraform, "init", "-input=false"], working_directory, env)
        run([terraform, "apply", "-input=false", "-auto-approve"], working_directory, env)
        raw_output = run(
            [terraform, "output", "-json", "lookup"], working_directory, env
        )

    payload = json.loads(raw_output)
    organizations = payload.get("organizations") or []
    target = normalize(args.workspace_name)
    exact_matches = [
        organization
        for organization in organizations
        if normalize(organization.get("name", "")) == target
    ]
    fuzzy_matches = [
        organization
        for organization in organizations
        if organization not in exact_matches
        and target in normalize(organization.get("name", ""))
    ]

    result = {
        "query": args.workspace_name,
        "selected": exact_matches[0] if len(exact_matches) == 1 else None,
        "exact_matches": sorted(exact_matches, key=lambda item: item.get("name", "")),
        "fuzzy_matches": sorted(fuzzy_matches, key=lambda item: item.get("name", "")),
        "match_count": {
            "exact": len(exact_matches),
            "fuzzy": len(fuzzy_matches),
            "visible_organizations": len(organizations),
        },
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
