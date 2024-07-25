1.Create storage Account 

az group create --name <name for resource group> --location <region>

2.Run the file

az deployment group create --resource-group <your-resource-group> --template-file <bicep file name> --parameters adminUsername=azureuser adminPassword=<YourComplexPassword123!>
