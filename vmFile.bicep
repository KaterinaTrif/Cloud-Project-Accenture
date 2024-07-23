param location string = resourceGroup().location
param vnetName string = 'InternalVNet'
param vnetAddress string = '10.0.0.0/16'
param subnet1Name string = 'deploymentSubnet'
param subnet1Address string = '10.0.1.0/24'
param subnet2Name string = 'testingSubnet'
param subnet2Address string = '10.0.2.0/24'
param storageSubnet string = 'StorageSubnet'
param storageSubAddress string = '10.0.3.0/24'
param devVmSize string = 'Standard_B1s'  //'Standard_D4s_v3'
param testVmSize string = 'Standard_B1s' //'Standard_D2s_v3'
//unique name for storgae account
param storageAccountName string = 'vmStorageAccount${uniqueString(resourceGroup().id)}'

param adminUsername string
@secure()
param adminPassword string

//num of vms 
var deploymentVMCount = 2
var testingVMCount = 1

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
  name: take(storageAccountName, 24) //max 24 chars
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
  properties: {
    //allow access only from the specified subnet 
    //and deny all other traffic by default.
    networkAcls: {
      virtualNetworkRules: [
        {
          id: '${vnet.id}/subnets/${storageSubnet}'
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
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
