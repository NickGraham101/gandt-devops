Describe "Set-DockerImageTag Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../PSScripts/
    }

    Context "Main/master branch" {
        It "Should set DockerImageTag to the build number" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "main"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]20260831.1"
        }
    }

    Context "PR merge branch" {
        It "Should set DockerImageTag to prbuild" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "merge"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]prbuild"
        }
    }

    Context "Sprint feature branch" {
        It "Should set DockerImageTag to the sprint number" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "024-MyFeatureBranch"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]Branch024"
        }
    }

    Context "Bug branch" {
        It "Should set DockerImageTag to the bug number" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "B099-FixSomething"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]BranchB099"
        }
    }

    Context "Dependabot branch" {
        It "Should set DockerImageTag to Dependabot" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "DEP-2026-08-31"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]Dependabot"
        }
    }

    Context "Marketing branch" {
        It "Should set DockerImageTag to Marketing without requiring a date" {
            $Output = .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "MKT-SummerCampaign"
            $Output | Should -Be "##vso[task.setvariable variable=DockerImageTag]Marketing"
        }
    }

    Context "Invalid branch name" {
        It "Should throw" {
            { .\Set-DockerImageTag.ps1 -BuildBuildNumber "20260831.1" -BuildSourceBranchName "not-a-valid-branch" } | Should -Throw
        }
    }
}
