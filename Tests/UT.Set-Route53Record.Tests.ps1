Describe "Set-Route53Record Unit Tests" -Tags @("Unit") {

    BeforeAll {
        Set-Location $PSScriptRoot/../PSScripts/
        Import-Module AWSPowerShell.NetCore

        Mock Set-AWSCredential

        Mock Get-R53Hostedzones -MockWith {
            return @{
                Id = "not-a-real-zone-id"
            }
        }

        Mock Edit-R53ResourceRecordSet
    }

    Context "CName params without AWS creds are used" {
        It "Should create a CName record without authenticating to AWS" {
            $TestParams = @{
                DomainName = "grahamandtonic.com."
                CNameRecordName = "bar"
                CNameRecordValue = "foo.example.com"
            }

            { .\Set-Route53Record.ps1 @TestParams } | Should -Not -Throw
            Assert-MockCalled -CommandName Set-AWSCredential -Exactly -Times 0
            Assert-MockCalled -CommandName Edit-R53ResourceRecordSet -ParameterFilter { $ChangeBatch_Change.ResourceRecordSet.Type -eq "CNAME" } -Exactly -Times 1
        }
    }

    Context "CName params with AWS creds are used" {
        It "Should authenticate to AWS and create a CName record" {
            $TestParams = @{
                DomainName = "example.com."
                CNameRecordName = "bar"
                CNameRecordValue = "foo.example.com"
                AwsAccessKey = "not-a-real-key"
                AwsSecretKey = "not-a-real-secret"
            }

            { .\Set-Route53Record.ps1 @TestParams } | Should -Not -Throw
            Assert-MockCalled -CommandName Set-AWSCredential -Exactly -Times 1
            Assert-MockCalled -CommandName Edit-R53ResourceRecordSet -ParameterFilter { $ChangeBatch_Change.ResourceRecordSet.Type -eq "CNAME" } -Exactly -Times 1
        }
    }

    Context "A record params without AWS creds are used" {
        It "Should create an A record without authenticating to AWS" {
            $TestParams = @{
                DomainName = "example.com."
                HostName = "foo"
                IpAddress = "10.0.0.10"
            }

            { .\Set-Route53Record.ps1 @TestParams } | Should -Not -Throw
            Assert-MockCalled -CommandName Set-AWSCredential -Exactly -Times 0
            Assert-MockCalled -CommandName Edit-R53ResourceRecordSet -ParameterFilter { $ChangeBatch_Change.ResourceRecordSet.Type -eq "A" } -Exactly -Times 1
        }
    }

    Context "A record params with AWS creds are used" {
        It "Should authenticate to AWS and create an A record" {
            $TestParams = @{
                DomainName = "example.com."
                HostName = "foo"
                IpAddress = "10.0.0.10"
                AwsAccessKey = "not-a-real-key"
                AwsSecretKey = "not-a-real-secret"
            }

            { .\Set-Route53Record.ps1 @TestParams } | Should -Not -Throw
            Assert-MockCalled -CommandName Set-AWSCredential -Exactly -Times 1
            Assert-MockCalled -CommandName Edit-R53ResourceRecordSet -ParameterFilter { $ChangeBatch_Change.ResourceRecordSet.Type -eq "A" } -Exactly -Times 1
        }
    }
}
