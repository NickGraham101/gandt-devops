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
    [Parameter(Mandatory = $true)]
    [string]$SourceBranchName,
    [Parameter(Mandatory = $true)]
    [string]$TeamProjectId
)

Import-Module $ModulePath
if ($SourceBranchName -match "refs\/heads\/") {
    $Segments = ($SourceBranchName -split "/").Count
    $SourceBranchName = ($SourceBranchName -split "/")[2..($Segments-1)] -join "/"
    Write-Verbose "Setting SourceBranchName to '$SourceBranchName'"
}

# if $SourceBranchName contains a http reserved character, eg #, then the Git-Diff call will probably fail.  Url escaping $SourceBranchName didn't resolve the problem

$SharedParams = @{
  Instance = $AzureDevOpsOrganizationName
  PatToken = $AccessToken
  ProjectId = $TeamProjectId
  RepositoryId = $RepositoryId
  BaseBranch = "master"
  TargetBranch = "$SourceBranchName"
  MinFolderPathSegmentLength = 2
  MaxFolderPathSegmentLength = 4
}

Write-Verbose "SharedParams: $($SharedParams | Out-String)"

$Diff = Get-Diff  @SharedParams

$PathsChanged = $Diff.PathsChanged -join ","
Write-Output "PathsChanged: $PathsChanged"
Write-Output "##vso[task.setvariable variable=PathsChanged;isOutput=true]$PathsChanged"

$FilesChanged = $Diff.FilesChanged -join ","
Write-Output "FilesChanged: $FilesChanged"
Write-Output "##vso[task.setvariable variable=FilesChanged;isOutput=true]$FilesChanged"

$FileTypesChanged = $Diff.FileTypesChanged -join ","
Write-Output "FileTypesChanged: $FileTypesChanged"
Write-Output "##vso[task.setvariable variable=FileTypesChanged;isOutput=true]$FileTypesChanged"
