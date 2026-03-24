# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

**Type:** Public (GitHub)
**Remote:** `https://github.com/NickGraham101/gandt-devops`

**Branch naming:** UpperCamelCase with no separators (e.g. `MyFeatureBranch`).

**Worktrees:** Create in `../gandt-devops-worktrees/<branch-name>/` — never inside this directory.

## Repository Purpose

Shared DevOps toolkit providing reusable ARM templates, Azure DevOps pipeline templates, and PowerShell scripts for CI/CD pipelines. Consumed by downstream pipelines via multi-repo checkout and pinned by tag — update the pinned tag in consumer pipelines when releasing new versions.

## Testing

Requires PowerShell with **Pester** and **PSScriptAnalyzer** modules installed.

```powershell
# Run all tests
./Tests/Invoke-Tests.ps1

# Run specific test type
./Tests/Invoke-Tests.ps1 -TestType Unit
./Tests/Invoke-Tests.ps1 -TestType Quality
./Tests/Invoke-Tests.ps1 -TestType Acceptance
```

Tests output JUnit XML to `Tests/TEST-<TestType>.xml`. GitHub Actions runs these on every push via `.github/workflows/test.yml`.

Quality tests (`QT.Quality.Tests.ps1`) use PSScriptAnalyzer to lint all PowerShell scripts. Unit tests live alongside subjects as `UT.<ScriptName>.Tests.ps1`.

## Architecture

### AzureDevOpsTemplates/

Pipeline templates consumed by downstream repos via multi-repo checkout. Organized by phase and granularity:

- `Build/StepTemplates/` — individual build steps (dotnet build+test, docker tag, GitVersion fix)
- `Build/JobTemplates/` — full build jobs (Pulumi preview)
- `Build/StageTemplates/` — full stages (Dependabot automation, scheduled job reporting)
- `Deploy/StepTemplates/` — individual deploy steps (ARM deploy, Kubernetes namespace/secret/exec/check, Pulumi up)

Templates detect multi-repo checkout context and adjust script paths accordingly.

### PSScripts/

Standalone PowerShell scripts invoked by the ADO templates. Key scripts:

| Script | Purpose |
|--------|---------|
| `New-ParametersFile.ps1` | Generates ARM parameters JSON from environment variables |
| `ConvertTo-AzureDevOpsVariables.ps1` | Maps ARM template outputs → ADO pipeline variables |
| `Get-GitChanges.ps1` | Detects which path segments changed in a PR (used for conditional pipeline triggers) |
| `Set-DockerImageTag.ps1` | Sets Docker image tag based on branch + build number |
| `Test-KubernetesDeploymentSucceeded.ps1` | Polls K8s deployment rollout status |
| `Test-AllTestResults.ps1` | Aggregates multiple JUnit XML results; fails if any contain failures |
| `Test-DependabotPullRequest.ps1` | Validates and auto-merges Dependabot PRs |
| `Export-KeyVaultSecrets.ps1` / `Import-KeyVaultSecrets.ps1` | Migrate secrets between Key Vaults |

### ARMTemplates/

Azure Resource Manager templates (JSON) for provisioning: AKS cluster, Key Vault, Storage Account, Application Insights, Log Analytics Workspace. Each template has a companion `.md` documenting its parameters.

### arm-deploy.yml template flow

1. Calls `New-ParametersFile.ps1` to build a parameters JSON from pipeline variables
2. Runs `az deployment group create` (or `what-if`) with the generated file
3. Calls `ConvertTo-AzureDevOpsVariables.ps1` to export ARM outputs as ADO variables for downstream steps
