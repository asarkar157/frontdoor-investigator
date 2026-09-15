# Repository Instructions

Read `.agents/skills/frontdoor-investigator-aiden-deployer/SKILL.md` before deploying or updating this module in Aiden/StackGen.

- Preserve existing Jira integrations and knowledge-base documents.
- Never substitute a native Kubernetes integration; all Kubernetes access must use kubectl through the configured Ubuntu CLI integration and remote runner.
- Treat Terraform changes as additive unless the user explicitly requests deletion or replacement.
- Do not add a `codex` prefix to branches or add Codex as a commit co-author.
