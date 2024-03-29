# Azure Kubernetes Service

Creates Azure Kubernetes Service

## Parameters

adminGroupObjectId (required) string

The objectId GUID of the AAD group that will be granted admin priviledges on the cluster

clusterName (required) string

The name of the Managed Cluster resource.

dnsServiceIp (required) string

kubernetesVersion (required) string

The version of Kubernetes.

nodeResourceGroup (required) string

The name of the resource group used for nodes

serviceCidr (required) string

subnetName (required) string

Subnet name that will contain the aks CLUSTER

virtualNetworkName (required) string

Name of an existing VNET that will contain this AKS deployment.

virtualNetworkResourceGroup (required) string

Name of the existing VNET resource group

agentPools (optional) array

An object containing agentNodeCount, agentPoolName, agentVMSize and mode properties
agentNodeCount is number of nodes for the pool.  Defaults to 3, minimum of 1, maximum of 50.
agentVMSize is the sku of the machines that will be used for the default agentpool.  Defaults to 'Standard_DS2_v2'.  If multiple SKUs are passed in each node pool will be of the same size.
mode must be either System or User

dockerBridgeCidr (optional) string

Defaults to 172.17.0.1/16

logAnalyticsResourceGroupName (optional) string

The name of the resource group for log analytics.  Defaults to "", by default a Log Analytics Workspace is not required.

logAnalyticsWorkspaceName (optional) string

The name of the log analytics workspace that will be used for monitoring.  Defaults to "", by default a Log Analytics Workspace is not required.

podCidr (optional) string

Defaults to 10.244.0.0/16

