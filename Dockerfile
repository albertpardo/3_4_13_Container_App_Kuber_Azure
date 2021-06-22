# To enable ssh & remote debugging on app service change the base image to the one below
# FROM mcr.microsoft.com/azure-functions/python:3.0-python3.9-appservice
FROM mcr.microsoft.com/azure-functions/python:3.0-python3.9

ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

ENV MyDbConnection=mongodb://myazurecosmosdblab22bis:fE2D2hYbkEFHbrkvLsDY9BdZ1kYDCmZakn6u7njlkWmuhUI0Md4UZAL4td8IkjlFbshjtJPciskNOdKEmZ6dXw==@myazurecosmosdblab22bis.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@myazurecosmosdblab22bis@

COPY requirements.txt /
RUN pip install -r /requirements.txt

COPY . /home/site/wwwroot