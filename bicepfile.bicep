// Define the resource group location
param location string = resourceGroup().location

//parameters for VM
param vmName string = 'multosoftwareVM'
param vmSize string = 'Standard_B1s'  //Free

//parametres for network
param virtualNetworkName string = 'multisoftwareNetwork'
param deploymentSubnetName string = 'deploymentSubnet'
param testingSubnetName string = 'testingSubnet'
param addressPrefix string = '10.0.0.0/16'
param deplymentSubnetPrefix string = '10.0.0.0/24'
param testingSubnetPrefix string = '10.0.1.0/24'



