#   Previous steps :
(I'm using Udacity Cloud Lab on Azure VM)
(Some ideas extracted from : https://knowledge.udacity.com/questions/561123)

1. Log to azure portal and create a *Function App*. Parameters:
    * Function App Name  : **course2demoalb**
    * Publish : **code**
    * Runtime stack : **Python**
    * Version : **3.9**   ( it's my local version)
    * Region : <Same as Resource Group>

2. Create *getNotes* and *getNote* using VScode. 

3. Generate Docker file with :
   * func init --docker-only


4. In Cli :
    * source .venv/bin/activate
    * az login
5. To create cosmosdb with data, run :
    * setup_mongodb_albert.sh

6. Get **Primary Connection String** from my DB in COSMOSDB

7. Add the next line to DOCKER file with **Primary Connection String**:
   * ENV MyDbConnection=<HERE THE  Primary Connection String to COSMOSDB>



8.  Get the resource group and location

```sh
export RESOURCE_GROUP=$(az group list --query "[0].name" -o tsv)
export REGION=$(az group show --name $RESOURCE_GROUP | jq -r ".location")
printf "\nThe resource group is called $RESOURCE_GROUP and is located in $REGION\n"
```

9. Get STORAGE_ACCOUNT by shell way

```sh
export STORAGE_ACCOUNT_NAME=$(az storage account list --query "[0].name" -o tsv)
printf "\nSTORAGE_ACCOUNT_NAME : $STORAGE_ACCOUNT_NAME\n"
```

10. create container registry

```sh
export APP_REGISTRY="containerRegistryAlb"
export REGION2=$REGION

az acr create --resource-group $RESOURCE_GROUP \
    --name $APP_REGISTRY \
    --sku Basic \
    --location $REGION2 \
    --admin-enabled true
```

11. get credentials

```sh
export ACR_USERNAME=$(az acr credential show --name $APP_REGISTRY --query username --output tsv)
export ACR_PASSWORD=$(az acr credential show --name $APP_REGISTRY --query passwords[0].value --output tsv)
printf "\nThe ACR_USERNAME : $ACR_USERNAME with ACR_PASSWORD : $ACR_PASSWORD\n"
```

12. login to the ACR. make sure that your local docker client is running

```sh
docker login ${APP_REGISTRY}.azurecr.io --username $ACR_USERNAME --password $ACR_PASSWORD
```
13. I get the next message:

```sh
WARNING! Using --password via the CLI is insecure. Use --password-stdin.
WARNING! Your password will be stored unencrypted in /home/usuari1/.docker/config.json.
Configure a credential helper to remove this warning. See https://docs.docker.com/engine/reference/commandline/login/#credentials-store
```

13. Create Docker image:

```sh
export DOCKER_IMAGE_NAME="myfirstgetnotes"
docker build --tag $DOCKER_IMAGE_NAME .
```

14. test docker image locally

```sh
docker run -p 8080:80 -it $DOCKER_IMAGE_NAME
```

15. open http://localhost:8080/api/getNotes in your web browser to confirm that the container is running.
16. Get one note : http://localhost:8080/api/getNote?_id=5ed43a30a5193402a6b11da0

17. build docker image for ACR

```sh
docker build --tag ${APP_REGISTRY}.azurecr.io/${DOCKER_IMAGE_NAME}:v1 .
```
18. push image to ACR

```sh
docker push ${APP_REGISTRY}.azurecr.io/${DOCKER_IMAGE_NAME}:v1
```
19. confirm that the image was pushed to the ACR

```sh
az acr repository list --name ${APP_REGISTRY}.azurecr.io --output table
```
20. create AKS cluster

```sh
export AKS_NAME="aks-notes-cluster"


21. This give me an error 

```sh
az aks create --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --node-count 2 \
    --generate-ssh-keys \
    --location $REGION2 \
    --attach-acr $APP_REGISTRY
```

22. Get the next message:

```sh
 Operation failed with status: 'Bad Request'. Details: Provisioning of resource(s) for container service aksname in resource group cloud-demo-147352 failed. Message: Resource 'aks-nodepool1-14580626-vmss' was disallowed by policy. Policy identifiers: '[{"policyAssignment":{"name":"cloud-demo388-PolicyDefinition-cloud-demo-147352","id":"/subscriptions/2ad620c9-609b-45ef-aaf8-dbb92d8b0662/resourceGroups/cloud-demo-147352/providers/Microsoft.Authorization/policyAssignments/cloud-demo388-PolicyDefinition-cloud-demo-147352"},"policyDefinition":{"name":"cloud-demo388-PolicyDefinition","id":"/subscriptions/2ad620c9-609b-45ef-aaf8-dbb92d8b0662/providers/Microsoft.Authorization/policyDefinitions/cloud-demo388-PolicyDefinition"}}]'.. Details:
```

23. Solution create AKS on Azure portal following the video :
    * 11 - 1 - ND081 C2 L3 09 Deploying Your App With Kubernetes Video 
    * Node must be: B2_S and change the authentication to get "container registry"
 
24. get AKS credentials

```sh
az aks get-credentials -g $RESOURCE_GROUP -n $AKS_NAME
```

25- **210622**: Optional no tested  (from https://knowledge.udacity.com/questions/613679)

```sh
az aks update -n $AKS_NAME -g$RESOURCE_GROUP --attach-acr $APP_REGISTRY
```

27. Kubernetes for debian in https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

28. verify AKS connection

```sh
kubectl get nodes
```

29. get keda

```sh
func kubernetes install --namespace keda
```

30. deploy image from ACR to AKS

```sh
func kubernetes deploy --name $AKS_NAME --image-name ${APP_REGISTRY}.azurecr.io/${DOCKER_IMAGE_NAME}:v1 --polling-interval 3 --cooldown-period 5
```

31. Answer:

```sh
secret/aks-notes-cluster created
secret/func-keys-kube-secret-aks-notes-cluster created
serviceaccount/aks-notes-cluster-function-keys-identity-svc-act created
role.rbac.authorization.k8s.io/functions-keys-manager-role created
rolebinding.rbac.authorization.k8s.io/aks-notes-cluster-function-keys-identity-svc-act-functions-keys-manager-rolebinding created
service/aks-notes-cluster-http created
deployment.apps/aks-notes-cluster-http created
Waiting for deployment "aks-notes-cluster-http" rollout to finish: 0 of 1 updated replicas are available...
deployment "aks-notes-cluster-http" successfully rolled out
	getNote - [httpTrigger]
	Invoke url: http://20.189.17.193/api/getnote

	getNotes - [httpTrigger]
	Invoke url: http://20.189.17.193/api/getnotes

	Master key: pSYgtUTuIa5reMATlfIz6wUBynMtOgahDaMs0USpRt8omNfMNs4Xog==
```

32. Get service

```sh
$ kubectl get service
NAME                     TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
aks-notes-cluster-http   LoadBalancer   10.0.144.26   20.189.17.193   80:30355/TCP   6m32s
kubernetes               ClusterIP      10.0.0.1      <none>          443/TCP        28m
```


33. I connect to  http://20.189.17.193/api/getnotes  but get :


```sh
Could not connect to mongodb
```