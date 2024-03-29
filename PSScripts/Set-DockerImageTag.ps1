[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [String]$BuildBuildNumber,
    [Parameter(Mandatory=$true)]
    [String]$BuildSourceBranchName
)

if ($BuildSourceBranchName -eq "master") {

    Write-Output "##vso[task.setvariable variable=DockerImageTag]$BuildBuildNumber"
    Write-Verbose "DockerImageTag set to '$BuildBuildNumber'"

}
elseif ($BuildSourceBranchName -eq "merge") {

    Write-Output "##vso[task.setvariable variable=DockerImageTag]prbuild"
    Write-Verbose "DockerImageTag set to 'prbuild'"

}
else {

    if ($BuildSourceBranchName -match "^(\d{3}|B\d{3})-\w*") {

        Write-Output "##vso[task.setvariable variable=DockerImageTag]Branch$($Matches[1])"
        Write-Verbose "DockerImageTag set to 'Branch$($Matches[1])'"

    }
    elseif ($BuildSourceBranchName -match "^DEP-\d{4}-\d{2}-\d{2}$") {
        Write-Output "##vso[task.setvariable variable=DockerImageTag]Dependabot"
        Write-Verbose "DockerImageTag set to 'Dependabot'"
    }
    else {

        throw "Branch name invalid, must match pattern '^(\d{3}|B\d{3})-\w*' or '^DEP-\d{4}-\d{2}-\d{2}$'"

    }

}
