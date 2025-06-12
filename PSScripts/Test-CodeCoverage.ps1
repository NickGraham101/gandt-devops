[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$AccessToken,
    [Parameter(Mandatory=$true)]
    [string]$AzureDevOpsOrganizationName,
    [Parameter(Mandatory=$true)]
    [string]$AzureDevOpsToolsPath,
    [Parameter(Mandatory=$true, ParameterSetName = "BaselineFromBranch")]
    [string]$BaselineBranchName,
    [Parameter(Mandatory=$true)]
    [string]$BuildDefinitionId,
    [Parameter(Mandatory=$true)]
    [string]$ComparisonBuildId,
    [Parameter(Mandatory=$true)]
    [string]$AzDevOpsProject
)

Import-Module $AzureDevOpsToolsPath

$BaseParams = @{
  Instance = $AzureDevOpsOrganizationName
  PatToken = $AccessToken
  ProjectId = $AzDevOpsProject
}

$ComparisonBuildCodeCoverageParams = $BaseParams.Clone()
if ($PSCmdlet.ParameterSetName -eq "BaselineFromBranch") {
    $GetBuildParams = $BaseParams.Clone()
    $GetBuildParams["BuildDefinitionId"] = $BuildDefinitionId
    $GetBuildParams["BranchName"] = $BaselineBranchName
    $MasterBuilds = Get-Build @GetBuildParams
    Write-Verbose "$($MasterBuilds | Out-String)"
    $BuildCounter = 0
    $ComparisonBuildCodeCoverageParams["BuildId"] = "$($MasterBuilds[$BuildCounter].BuildId)"
}
$ComparisonBuildCodeCoverage = Get-CodeCoverage @ComparisonBuildCodeCoverageParams
while (!$ComparisonBuildCodeCoverage) {
    $BuildCounter++
    $ComparisonBuildCodeCoverageParams["BuildId"] = "$($MasterBuilds[$BuildCounter].BuildId)"
    $ComparisonBuildCodeCoverage = Get-CodeCoverage @ComparisonBuildCodeCoverageParams

    if ($BuildCounter -ge $MasterBuilds.Count) {
        throw "No code coverage results returned for comparison build $($ComparisonBuildCodeCoverageParams["BuildId"])"
    }
}

$CurrentBuildCoverCoverageParams = $BaseParams.Clone()
$CurrentBuildCoverCoverageParams["BuildId"] = $ComparisonBuildId
$CurrentBuildCoverCoverage = Get-CodeCoverage @CurrentBuildCoverCoverageParams
if (!$CurrentBuildCoverCoverage) {
    throw "No code coverage results returned for current build $($CurrentBuildCoverCoverageParams["BuildId"])"
}

Write-Verbose "Last master build code coverage was $($ComparisonBuildCodeCoverage.LineCoverage.Percentage)"
Write-Verbose "Current build code coverage was $($CurrentBuildCoverCoverage.LineCoverage.Percentage)"

$RoundedComparison = [math]::Round($ComparisonBuildCodeCoverage.LineCoverage.Percentage, 1)
$RoundedCurrent = [math]::Round($CurrentBuildCoverCoverage.LineCoverage.Percentage, 1)
if ($RoundedCurrent -lt $RoundedComparison) {
    throw "CodeCoverage has reduced from $($RoundedComparison) to $($RoundedCurrent), failing pipeline run."
}
