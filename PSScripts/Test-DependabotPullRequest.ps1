[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AccessToken,
    [Parameter(Mandatory = $true)]
    [string]$AzureDevOpsOrganizationName,
    [Parameter(Mandatory = $true)]
    [string]$ModulePath,
    [Parameter(Mandatory = $true)]
    [string]$RepositoryId,
    [Parameter(Mandatory = $false, ParameterSetName="PullRequestId")]
    [string]$PullRequestId,
    [Parameter(Mandatory = $true)]
    [string]$TeamProjectId
)

Write-Output "##vso[task.setvariable variable=RunAllBuildJobs;isOutput=true]$true"

if ($PSCmdlet.ParameterSetName -eq "PullRequestId") {

    Import-Module $ModulePath

    $SharedParams = @{
      Instance = $AzureDevOpsOrganizationName
      PatToken = $AccessToken
      ProjectId = $TeamProjectId
      RepositoryId = $RepositoryId
      PullRequestId = $PullRequestId
    }

    Write-Verbose "SharedParams: $($SharedParams | Out-String)"

    $PullRequest = Get-PullRequest  @SharedParams

    if ($PullRequest.Labels -contains "dependencies") {
        Write-Output "RunAllBuildJobs: $false"
        Write-Output "##vso[task.setvariable variable=RunAllBuildJobs;isOutput=true]$false"
    }

}
