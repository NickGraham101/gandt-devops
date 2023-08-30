[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [String]$Emoji,
    [Parameter(Mandatory = $true)]
    [String]$FallBackMessage,
    [Parameter(Mandatory = $true)]
    [String]$MarkdownMessage,
    [Parameter(Mandatory = $true)]
    [String]$MessageTitle,
    [Parameter(Mandatory = $true)]
    [String]$SlackApiUrl
)

$Body = @{
    username = $MessageTitle
    text     = $FallBackMessage
    blocks   = @(
        @{
            type = "section"
            text = @{
                type = "mrkdwn"
                text = $MarkdownMessage
            }
        }
    )
    icon_emoji = $Emoji
}

Invoke-RestMethod -Method Post -Body ($Body | ConvertTo-Json -Depth 20) -Uri $SlackApiUrl -ErrorAction Stop
