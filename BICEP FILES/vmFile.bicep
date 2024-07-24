param location string = resourceGroup().location
param vnetName string = 'InternalVNet'
param subnet1Name string = 'deploymentSubnet'
param subnet2Name string = 'testingSubnet'
param storageSubnet string = 'StorageSubnet'
param bastionName string = 'Bastion'

param vnetAddress string = '10.0.0.0/22'
param subnet1Address string = '10.0.0.0/24'
param subnet2Address string = '10.0.1.0/24'
param storageSubAddress string = '10.0.2.0/24'
param bastionSubAdreess string = '10.0.3.0/27'

param devVmSize string = 'Standard_D4s_v4'  
param testVmSize string = 'Standard_D2s_v3' 
//unique name for storgae account
// unique name for storage account
param storageAccountNamePrefix string = 'vmstorageacct'
var storageAccountName = toLower('${storageAccountNamePrefix}${uniqueString(resourceGroup().id)}')

// Check length and trim if necessary
var finalStorageAccountName = length(storageAccountName) > 24 ? take(storageAccountName, 24) : storageAccountName

param adminUsername string
@secure()
param adminPassword string

//num of vms 
var deploymentVMCount = 100
var testingVMCount = 30

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: subnet1Name
        properties: {
          addressPrefix: subnet1Address
        }
      }
      {
        name: subnet2Name
        properties: {
          addressPrefix: subnet2Address
        }
      }
      {
        name: storageSubnet
        properties: {
          addressPrefix: storageSubAddress
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubAdreess
        }
      }

    ]
  }
}

// Create a public IP for Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${bastionName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create the Bastion host
resource bastionHost 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: bastionName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}


resource deploymentNics 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, deploymentVMCount): {
  name: 'nic-deploy-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource testingNics 'Microsoft.Network/networkInterfaces@2021-05-01' = [for i in range(0, testingVMCount): {
  name: 'nic-test-${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[1].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}]

resource deploymentVMs 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, deploymentVMCount): {
  name: 'vm-deploy-${i}' //unique names for depoyment vms 
  location: location
  properties: {
    hardwareProfile: {
      vmSize: devVmSize
    }
    osProfile: {
      computerName: 'vmdepl${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: deploymentNics[i].id //connection between vms and nics
        }
      ]
    }
  }
}]

resource testingVMs 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(0, testingVMCount): {
  name: 'vm-test-${i}' //unique names for testing vms 
  location: location
  properties: {
    hardwareProfile: {
      vmSize: testVmSize
    }
    osProfile: {
      computerName: 'vmtest${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: testingNics[i].id
        }
      ]
    }
  }
}]

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: finalStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'  // Changed from ZRS to LRS for testing
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}
