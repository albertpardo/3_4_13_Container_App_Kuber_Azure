#!/bin/bash

export COSMOSDB_ACCOUNT="myazurecosmosdblab22bis"
export DATABASE_NAME="lab1db"
export SAMPLE_COLLECTION="notes"
export CREATE_LEASE_COLLECTION=0     # yes,no=(1,0)

export PROVISION_THROUGHPUT="400"

export MONGODB_HOST=$COSMOSDB_ACCOUNT".mongo.cosmos.azure.com"
export MONGODB_PORT="10255"
export FILE_NAME_JSON="sample-db.json"     # Data file to import to DB in Azure

# Get the resource group and location
export RESOURCE_GROUP=$(az group list --query "[0].name" -o tsv)
export REGION=$(az group show --name $RESOURCE_GROUP | jq -r ".location")
printf "\nThe resource group is called $RESOURCE_GROUP and is located in $REGION\n"

# Get STORAGE_ACCOUNT by shell way
STORAGE_ACCOUNT_NAME=$(az storage account list --query "[0].name" -o tsv)
printf "\nSTORAGE_ACCOUNT_NAME : $STORAGE_ACCOUNT_NAME\n"

# Create COSMOS DB ACCOUNT
# export REGION2="westus2"
export REGION2=$REGION
printf "\nCreating COSMOS DB ACCOUNT: $COSMOSDB_ACCOUNT in region : $REGION2\n"
az cosmosdb create -n $COSMOSDB_ACCOUNT -g $RESOURCE_GROUP  --locations regionName=$REGION2 failoverPriority=0 isZoneRedundant=False --kind MongoDB

# Get your CosmosDB key and save as a variable
COSMOSDB_KEY=$(az cosmosdb keys list --name $COSMOSDB_ACCOUNT --resource-group $RESOURCE_GROUP --output tsv | awk '{print $1}')

# Create a database
printf "\nCreating database: $DATABASE_NAME\n"
az cosmosdb mongodb database create \
--account-name $COSMOSDB_ACCOUNT \
--name $DATABASE_NAME \
--resource-group $RESOURCE_GROUP

# Create a container with a collection
printf "\nCreating a container with a collection : $SAMPLE_COLLECTION\n"
az cosmosdb mongodb collection create \
--resource-group $RESOURCE_GROUP \
--account-name $COSMOSDB_ACCOUNT \
--database-name $DATABASE_NAME \
--name $SAMPLE_COLLECTION \
--throughput $PROVISION_THROUGHPUT

# Importing An Existing Database Collection
printf "\nImporting An Existing Database Collection to Azure : $FILE_NAME_JSON\n"
mongoimport -h $MONGODB_HOST:$MONGODB_PORT \
-d $DATABASE_NAME -c $SAMPLE_COLLECTION -u $COSMOSDB_ACCOUNT -p $COSMOSDB_KEY \
--ssl --jsonArray --file $FILE_NAME_JSON \
--writeConcern {w:0}
