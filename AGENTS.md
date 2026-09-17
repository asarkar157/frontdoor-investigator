# Repository Instructions

Read `.agents/skills/frontdoor-investigator-aiden-deployer/SKILL.md` before deploying or updating this module in Aiden/StackGen.

- Preserve existing Jira integrations and knowledge-base documents.
- Attach Jira only to the ticket coordinator. It reads and adds clarification comments using REST API v2; never fall back to v3.
- Keep operator/tool limitations separate from missing developer context and suppress repeated clarification asks.
- Never substitute a native Kubernetes integration; all Kubernetes access must use kubectl through the attached runner's shell. No Ubuntu CLI integration is required.
- Preserve runner names/identifiers already attached to the legacy agent. An unresolved runners API lookup or missing Jira API-version metadata is an unverified runtime capability, not by itself a reason to reject an otherwise valid in-place deployment.
- All GitHub access must use read-only gh api calls through that same shell tool and runner, with existing runner authentication. Never attach or fall back to a GitHub integration.
- Treat Terraform changes as additive unless the user explicitly requests deletion or replacement.
- Do not add a `codex` prefix to branches or add Codex as a commit co-author.
