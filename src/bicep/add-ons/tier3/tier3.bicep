/*
Copyright (c) Microsoft Corporation.
Licensed under the MIT License.
*/

targetScope = 'subscription'
/*

  PARAMETERS

  Here are all the parameters a user can override.

  These are the required parameters that Mission LZ Tier 3 workload does not provide a default for:
    - resourcePrefix

*/

// REQUIRED PARAMETERS

@minLength(3)
@maxLength(10)
@description('A prefix, 3 to 10 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourcePrefix string

@minLength(3)
@maxLength(6)
@description('A suffix, 3 to 6 characters in length, to append to resource names (e.g. "dev", "test", "prod", "mlz"). It defaults to "mlz".')
param resourceSuffix string = 'mlz'

@description('The region to deploy resources into. It defaults to the deployment location.')
param location string = deployment().location

@description('The subscription ID for the Identity Network and resources. It defaults to the deployment subscription.')
param workloadSubscriptionId string = subscription().subscriptionId

@description('MLZ Deployment output variables in json format. It defaults to the deploymentVariables.json.')
param mlzDeploymentVariables object = json(loadTextContent('../deploymentVariables.json'))
param hubSubscriptionId string = mlzDeploymentVariables.hub.Value.subscriptionId
param hubResourceGroupName string = mlzDeploymentVariables.hub.Value.resourceGroupName
param hubVirtualNetworkName string = mlzDeploymentVariables.hub.Value.virtualNetworkName
param hubVirtualNetworkResourceId string = mlzDeploymentVariables.hub.Value.virtualNetworkResourceId
param logAnalyticsWorkspaceResourceId string = mlzDeploymentVariables.logAnalyticsWorkspaceResourceId.Value
param logAnalyticsWorkspaceName string = mlzDeploymentVariables.logAnalyticsWorkspaceName.Value
param firewallPrivateIPAddress string = mlzDeploymentVariables.firewallPrivateIPAddress.Value
@description('[NIST/IL5/CMMC] Built-in policy assignments to assign, it defaults to "NIST". IL5 is only available for AzureUsGovernment and will switch to NIST if tried in AzureCloud.')
param policy string = mlzDeploymentVariables.policyName.Value
@description('When set to "true", deploys the Azure Policy set defined at by the parameter "policy" to the resource groups generated in the deployment. It defaults to "false".')
param deployPolicy bool = mlzDeploymentVariables.deployPolicy.Value


@description('When set to "true", enables Microsoft Defender for Cloud for the subscriptions used in the deployment. It defaults to "false".')
param deployDefender bool = mlzDeploymentVariables.deployDefender.Value
@description('Email address of the contact, in the form of john@doe.com')
param emailSecurityContact string = mlzDeploymentVariables.emailSecurityContact.Value


@description('The address prefix for the network spoke vnet.')
param virtualNetworkAddressPrefix string = '10.0.125.0/26'

@description('An array of Network Diagnostic Logs to enable for the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#logs for valid settings.')
param virtualNetworkDiagnosticsLogs array = []

@description('An array of Network Diagnostic Metrics to enable for the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/azure-monitor/essentials/diagnostic-settings?tabs=CMD#metrics for valid settings.')
param virtualNetworkDiagnosticsMetrics array = []

@description('An array of Network Security Group rules to apply to the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/templates/microsoft.network/networksecuritygroups/securityrules?tabs=bicep#securityrulepropertiesformat for valid settings.')
param networkSecurityGroupRules array = []

@description('An array of Network Security Group diagnostic logs to apply to the workload Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param networkSecurityGroupDiagnosticsLogs array = [
  {
    category: 'NetworkSecurityGroupEvent'
    enabled: true
  }
  {
    category: 'NetworkSecurityGroupRuleCounter'
    enabled: true
  }
]
@description('An array of Network Security Group diagnostic logs to apply to the SharedServices Virtual Network. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-nsg-manage-log#log-categories for valid settings.')
param networkSecurityGroupDiagnosticsMetrics array = []

@description('The CIDR Virtual Network Address Prefix for the Workload Virtual Network.')
param subnetAddressPrefix string = '10.0.125.0/27'

@description('An array of Service Endpoints to enable for the Operations subnet. See https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview for valid settings.')
param subnetServiceEndpoints array = []

@description('The Storage Account SKU to use for log storage. It defaults to "Standard_GRS". See https://docs.microsoft.com/en-us/rest/api/storagerp/srp_sku_types for valid settings.')
param logStorageSkuName string = 'Standard_GRS'

@description('A string dictionary of tags to add to deployed resources. See https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=json#arm-templates for valid settings.')
param tags object = {} 

@description('A suffix to use for naming deployments uniquely. It defaults to the Bicep resolution of the "utcNow()" function.')
param deploymentNameSuffix string = utcNow()

@description('The name of the tier 3 workload')
param workloadName string = 'workload'

@maxLength(24)
@description('The name of the Storage Account if using this Parameter. Otherwise it will be a calculated value.')
param workloadLogStorageAccountNameParameter string = 'null'

/*

  NAMING CONVENTION

  Here we define a naming conventions for resources.

  First, we take `resourcePrefix` and `resourceSuffix` by params.
  Then, using string interpolation "${}", we insert those values into a naming convention.

*/

var resourceToken = 'resource_token'
var nameToken = 'name_token'
var namingConvention = '${toLower(resourcePrefix)}-${resourceToken}-${nameToken}-${toLower(resourceSuffix)}'

var resourceGroupNamingConvention = replace(namingConvention, resourceToken, 'rg')
var virtualNetworkNamingConvention = replace(namingConvention, resourceToken, 'vnet')
var networkSecurityGroupNamingConvention = replace(namingConvention, resourceToken, 'nsg')
var storageAccountNamingConvention = toLower('${resourcePrefix}st${nameToken}unique_storage_token')
var subnetNamingConvention = replace(namingConvention, resourceToken, 'snet')

var workloadResourceGroupName = replace(resourceGroupNamingConvention, nameToken, workloadName)
var workloadLogStorageAccountNameTemplate = replace(storageAccountNamingConvention, nameToken, toLower(workloadName))
var workloadLogStorageAccountUniqueName = replace(workloadLogStorageAccountNameTemplate, 'unique_storage_token', uniqueString(resourcePrefix, resourceSuffix, workloadSubscriptionId))
var workloadLogStorageAccountNameVariable = take(workloadLogStorageAccountUniqueName, 23)
var workloadVirtualNetworkName = replace(virtualNetworkNamingConvention, nameToken, workloadName)
var workloadNetworkSecurityGroupName = replace(networkSecurityGroupNamingConvention, nameToken, workloadName)
var workloadSubnetName = replace(subnetNamingConvention, nameToken, workloadName)
var logAnalyticsWorkspaceResourceId_split = split(logAnalyticsWorkspaceResourceId, '/')

var workloadLogStorageAccountName = 'null' != workloadLogStorageAccountNameParameter ? workloadLogStorageAccountNameParameter : workloadLogStorageAccountNameVariable

var defaultTags = {
  DeploymentType: 'MissionLandingZoneARM'
}
var calculatedTags = union(tags, defaultTags)

module resourceGroup '../../modules/resource-group.bicep' = {
  name: workloadResourceGroupName
  scope: subscription(workloadSubscriptionId)
  params: {
    name: workloadResourceGroupName
    location: location
    tags: calculatedTags
  }
}

module spokeNetwork '../../core/spoke-network.bicep' = {
  name: 'spokeNetwork'
  scope: az.resourceGroup(workloadSubscriptionId, resourceGroup.name)
  params: {
    tags: calculatedTags
    location:location    
    logStorageAccountName: workloadLogStorageAccountName
    logStorageSkuName: logStorageSkuName

    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId

    firewallPrivateIPAddress: firewallPrivateIPAddress

    virtualNetworkName: workloadVirtualNetworkName
    virtualNetworkAddressPrefix: virtualNetworkAddressPrefix
    virtualNetworkDiagnosticsLogs: virtualNetworkDiagnosticsLogs
    virtualNetworkDiagnosticsMetrics: virtualNetworkDiagnosticsMetrics

    networkSecurityGroupName: workloadNetworkSecurityGroupName
    networkSecurityGroupRules: networkSecurityGroupRules
    networkSecurityGroupDiagnosticsLogs: networkSecurityGroupDiagnosticsLogs
    networkSecurityGroupDiagnosticsMetrics: networkSecurityGroupDiagnosticsMetrics

    subnetName: workloadSubnetName
    subnetAddressPrefix: subnetAddressPrefix
    subnetServiceEndpoints: subnetServiceEndpoints
    subnetPrivateEndpointNetworkPolicies: 'Enabled'
  }
}

module workloadVirtualNetworkPeerings '../../core/spoke-network-peering.bicep' = {
  name: take('${workloadName}-to-hub-vnet-peering', 64)
  scope: subscription(workloadSubscriptionId)
  params: {
    spokeName: workloadName
    spokeResourceGroupName: resourceGroup.name
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName

    hubVirtualNetworkName: hubVirtualNetworkName
    hubVirtualNetworkResourceId: hubVirtualNetworkResourceId
  }
}

module hubToWorkloadVirtualNetworkPeering './modules/hub-network-peering.bicep' = {
  scope: subscription(hubSubscriptionId)
  name: take('hub-to-${workloadName}-vnet-peering', 64)
  params: {
    hubResourceGroupName: hubResourceGroupName
    hubVirtualNetworkName: hubVirtualNetworkName
    spokeVirtualNetworkName: spokeNetwork.outputs.virtualNetworkName
    spokeVirtualNetworkResourceId: spokeNetwork.outputs.virtualNetworkResourceId
  }
}

module workloadSubscriptionActivityLogging '../../modules/central-logging.bicep' = if (workloadSubscriptionId != hubSubscriptionId) {
  name: 'activity-logs-${spokeNetwork.name}-${resourceSuffix}'
  scope: subscription(workloadSubscriptionId)
  params: {
    diagnosticSettingName: 'log-${spokeNetwork.name}-sub-activity-to-${logAnalyticsWorkspaceName}'
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
  }
  dependsOn: [
    spokeNetwork
  ]
}

module workloadPolicyAssignment '../../modules/policy-assignment.bicep' = if (deployPolicy) {
  name: 'assign-policy-${workloadName}-${deploymentNameSuffix}'
  scope:  az.resourceGroup(workloadSubscriptionId, resourceGroup.name)
  params: {
    builtInAssignment: policy
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceResourceId_split[8]
    logAnalyticsWorkspaceResourceGroupName: logAnalyticsWorkspaceResourceId_split[4]
    location: location
    operationsSubscriptionId: logAnalyticsWorkspaceResourceId_split[2]
   }
  }
  
module spokeDefender '../../modules/defender.bicep' = if (deployDefender) {
  name: 'set-${workloadName}-sub-defender'
  scope: subscription(workloadSubscriptionId)
  params: {
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceResourceId
    emailSecurityContact: emailSecurityContact
  }
}

output resourceGroupName string = resourceGroup.outputs.name
output location string = resourceGroup.outputs.location
output tags object = resourceGroup.outputs.tags
output virtualNetworkName string = spokeNetwork.outputs.virtualNetworkName
output virtualNetworkAddressPrefix string = spokeNetwork.outputs.virtualNetworkAddressPrefix
output virtualNetworkResourceId string = spokeNetwork.outputs.virtualNetworkResourceId
output subnetName string = spokeNetwork.outputs.subnetName
output subnetAddressPrefix string = spokeNetwork.outputs.subnetAddressPrefix
output subnetResourceId string = spokeNetwork.outputs.subnetResourceId
output networkSecurityGroupName string = spokeNetwork.outputs.networkSecurityGroupName
output networkSecurityGroupResourceId string = spokeNetwork.outputs.networkSecurityGroupResourceId
