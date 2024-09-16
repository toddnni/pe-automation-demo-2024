Platform Engineering with Kubernetes Automation Demo 2024
=============================================

The idea is to demonstrate how you can use Kubernetes concepts to automate application infrastructure delivery.
The demo will install application stack that will manage Azure resources and external Git resource with Operators.

Features

- ASO, Azure Service Operator https://github.com/Azure/azure-service-operator
- Shell-operator https://github.com/flant/shell-operator

![Diagram that show the resource structure](overview.drawio.svg)

The demo is insecure and do not use this as baseline, note

- the Azure resources are exposed to public internet
- Kubernetes deployment is not hardened
- ASO uses full privileges in the subscription

Try out
======

Prerequisites
-------

Login and select the subscription

    az login
    az account list

Some defaults

    export LOCATION=swedencentral
    export SUBSCRIPTION="$(az account show --query id --output tsv)"
    export CLUSTER_NAME="myAKSCluster"
    export RESOURCE_GROUP="myAKSCluster"
    export ASO_IDENTITY="aso-manager"
    export TENANT=$(az account show --query tenantId --output tsv)

We need AKS cluster with workload identity support enabled

    az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"
    az aks create --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}" \
        --enable-oidc-issuer \
        --enable-workload-identity \
        --network-plugin azure \
        --network-plugin-mode overlay \
        --auto-upgrade-channel stable \
        --node-os-upgrade-channel NodeImage \
        --node-count 1 \
        --node-vm-size Standard_DS2_v2 \
        --generate-ssh-keys
    az aks get-credentials --resource-group "${RESOURCE_GROUP}" --name "${CLUSTER_NAME}"

Deploy the Platform stack with the following steps.

ASO https://azure.github.io/azure-service-operator/#installation

    kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.14.1/cert-manager.yaml
    helm repo add aso2 https://raw.githubusercontent.com/Azure/azure-service-operator/main/v2/charts
    # ASO identity and credentials
    export AKS_OIDC_ISSUER="$(az aks show --name "${CLUSTER_NAME}" \
        --resource-group "${RESOURCE_GROUP}" \
        --query "oidcIssuerProfile.issuerUrl" \
        --output tsv)"
    az identity create \
        --name "${ASO_IDENTITY}" \
        --resource-group "${RESOURCE_GROUP}" \
        --location "${LOCATION}" \
        --subscription "${SUBSCRIPTION}"
    export USER_ASSIGNED_CLIENT_ID="$(az identity show \
        --resource-group "${RESOURCE_GROUP}" \
        --name "${ASO_IDENTITY}" \
        --query 'clientId' \
        --output tsv)"
    az role assignment create --assignee "${USER_ASSIGNED_CLIENT_ID}" \
        --role "contributor" \
        --scope "/subscriptions/${SUBSCRIPTION}"
    az identity federated-credential create \
        --name ${ASO_IDENTITY}-federation \
        --identity-name "${ASO_IDENTITY}" \
        --resource-group "${RESOURCE_GROUP}" \
        --issuer "${AKS_OIDC_ISSUER}" \
        --subject system:serviceaccount:azureserviceoperator-system:azureserviceoperator-default \
        --audience api://AzureADTokenExchange
    # install
    helm upgrade --install aso2 aso2/azure-service-operator \
        --create-namespace \
        --namespace=azureserviceoperator-system \
        --set azureSubscriptionID=$SUBSCRIPTION \
        --set azureTenantID=$TENANT \
        --set azureClientID=$USER_ASSIGNED_CLIENT_ID \
        --set useWorkloadIdentityAuth=true \
        --set crdPattern='resources.azure.com/*;dbforpostgresql.azure.com/*;managedidentity.azure.com/*'

Shell operator.

Generate a GitHub personal access token (PAT) with minimal permissions for the repository you want to access. Make sure the token has access to:

- https://github.com/settings/personal-access-tokens/
- limit to the specific repository
- contents (write, needs for branches)
- PRs (write)

Install, replace the token here

    export GITHUB_TOKEN=github_pat_XXXX
    # You potentially need to edit the `network-glue/repo-url` as there is my repository hardcoded
    kubectl create namespace shell-operator
    kubectl create secret -n shell-operator generic git-token --from-literal=GIT_TOKEN="$GITHUB_TOKEN"
    kubectl apply -k network-glue

Demo
----

Needs a cluster and resources in the prerequisites, see above.

Initialize the application (see app.sh).
Start of the database instance takes about five minutes.

    APP=demo
    kubectl create ns "$APP"
    kubectl create secret -n "$APP" generic db-secret --from-literal=PASSWORD="$(openssl rand -base64 12)"

    cat > application-"$APP".values <<EOF
    image:
      repository: ghcr.io/toddnni/toddnni/pe-automation-demo-2024
      tag: latest
    azure:
      location: "$LOCATION"
      oidcIssuerUrl: "$AKS_OIDC_ISSUER"
      postgrePasswordSecret: "db-secret"
    network:
      targetCIDR: 192.168.0.3/24
    EOF

And deploy

    helm upgrade --install -n "$APP" --values application-"$APP".values "$APP" appstack-chart/

Monitor the Azure resources.

Cleanup
------

    helm uninstall -n "$APP" "$APP"

Wait until all the managed resources are deleted

    az aks delete --name "${CLUSTER_NAME}" --resource-group "${RESOURCE_GROUP}" --yes
    az group delete --resource-group "${RESOURCE_GROUP}" --yes

Devcontainer
------

There is Devcontainer that contain all the necessary tooling for the demo.

Start it for example with Devpod like this

    devpod up https://github.com/toddnni/pe-automation-demo-2024.git

Future reference
=====

User managed identity for postgres

    CREATE ROLE "<clientId-of-UMI>" WITH LOGIN INHERIT;
    GRANT ALL PRIVILEGES ON DATABASE <your_database> TO "<clientId-of-UMI>";

TODO
====

- demo hard to run as env variables here and there and need to be initialized
- go missing from devcontainer -> clean go.sums etc
- harden the configs
- use operator instead of helm chart
- make postgre managed identity to work, would require some postgre commands?
- network-glue do not create PR if no changes
- network-glue save status to crd
