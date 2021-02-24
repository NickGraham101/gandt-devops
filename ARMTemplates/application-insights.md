# Application Insights

Creates an App Insights

## Paramaters

appInsightsName: (required) string

Name of App Insight. Will be created in the same resource group as the script is run and in the default location for resource group.

attachedService: (optional) string

The app service (web app) the App Insight is monitoring.
This is just used as a tag.
If no attachedService is supplied, the tag is not created.

dailyQuota (optional) string
Enter daily quota in GB, accepts decimals, eg 0.25

dailyQuotaResetTime (optional) int
Enter daily quota reset hour in UTC (0 to 23). Values outside the range will get a random reset hour.

warningThreshold (optional) int
Enter the % value of daily quota after which warning mail to be sent.
