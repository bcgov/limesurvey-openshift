# LimeSurvey

Deploy a LimeSurvey instance leveraging Docker and Helm.

## Credits

This project is based on the work of [Byron Stuike](https://github.com/farghul), who created an initial version of this project using Podman and Ansible. The original work was licensed under the Unlicense. This version has been adapted for use with Docker and Helm, and is licensed under the Apache License 2.0.

![LimeSurvey logo](limesurvey.svg)

## Prerequisites

The following items are necessary for a successful deployment.

## Docker

Individually, the images can be built, tagged, and pushed to a container registry.

```bash
docker build --file Dockerfile --tag [name] .
docker image tag [name]:latest [repo]/[name]:[version]
docker push [repo]/[name]:[version]
```

### Github Actions Automation

Furthermore, there are Github Actions workflows defined in the `.github/workflows` directory to automate the build and deployment process. You may use these as a template when creating your own workflows.
The workflows expect the following to be set up in your Github repository:

- 3 [environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments): `dev`, `test`, and `prod`.
- Per-environment Github secrets for logging into Openshift and the container registry.
  - `OPENSHIFT_SERVER`: The URL of the OpenShift API server
  - `OPENSHIFT_SA_TOKEN`: The login token for your service account
  - `OPENSHIFT_SA_USER`: The service account's name
  - `OPENSHIFT_IMAGE_REGISTRY`: The registry URL (can often be found by replacing `api` in the OpenShift server URL with `image-registry`)
  - `OPENSHIFT_REPOSITORY`: The namespace in which the application is deployed, probably \<licenseplate\>-tools

To get a service account token, you can create a new ServiceAccount (or use an existing one, like `pipeline`). You will need to add the `system:image-builder` role for the registry to the ServiceAccount, as well as making sure it has the necessary permissions to deploy Helm charts. Note that the registry is likely at `<licenseplate>-tools`, so the RoleBinding should be created in the same namespace.

```bash
LICENSEPLATE=cd77be
NAME=limesurvey-pipeline
TAG=dev
NAMESPACE=$LICENSEPLATE-$TAG
REGISTRY=$LICENSEPLATE-tools
oc create serviceaccount $NAME -n $NAMESPACE
# Allow pushing to registry and create ImageStreams
oc create rolebinding $NAME-$TAG-push -n $REGISTRY \
  --clusterrole=system:image-builder \
  --serviceaccount=$NAMESPACE:$NAME
# Allow the service account to deploy Helm charts
oc create rolebinding $NAME-helm -n $NAMESPACE \
  --clusterrole=edit \
  --serviceaccount=$NAMESPACE:$NAME
# Create a Secret containing a token for the service account
echo "kind: Secret
apiVersion: v1
type: kubernetes.io/service-account-token
metadata:
  name: $NAME-token
  namespace: $NAMESPACE
  annotations:
    kubernetes.io/service-account.name: $NAME
" | oc create -f -
# Pass this token as OPENSHIFT_SA_TOKEN. Do not commit to git
echo "Token:"
oc get secret $NAME-token -n $NAMESPACE \
  -o jsonpath='{.data.token}' | base64 --decode
# Pass the serviceaccount name as OPENSHIFT_SA_USER
echo -e "\nServiceAccount:"
echo $NAME
```

## Openshift

The Vault user ( `<licenseplate>-vault; `see [Vault](#vault--secret-management)) needs to be authorized to pull images. For security reasons, we do not use Github Actions to deploy RBAC. You may manually create a RoleBinding giving the Vault user access to the `system:image-puller` role. Make sure that the role is created in the same namespace as the ImageStream you are pushing to (probably `<licenseplate>-tools`), but refers to the service account in the correct namespace (e.g, `<licenseplate>-dev`).

```bash
oc create rolebinding $NAMESPACE-vault -n $REGISTRY \
  --clusterrole=system:image-puller \
  --serviceaccount=$NAMESPACE:$NAME
```

## Helm

Adjust the necessary entries in the `helm/charts/values.yaml` file to target the correct namespace and use the desired host name.

```yaml
global:
  licensePlate: cd77be
  sectionTag: -dev
  replicaCount: 1
  image:
    # Note that this is the internal image registry address -
    # won't work in Github actions
    repository: image-registry.openshift-image-registry.svc:5000/
    imageStreamTag: latest
  host: "deseng-limesurvey-dev.apps.silver.devops.gov.bc.ca"
```

To manually trigger a deployment, navigate to the `helm` folder and run the following command:

```bash
helm upgrade --install limesurvey . --values values-<environment>.yaml
```

Note that `--values` is used to specify another file in addition to `values.yaml`. This will be the environment-specific file `values-dev.yaml`, `values-test.yaml`, or `values-prod.yaml`.

If you notice that the deployment is not picking up on changes to subcharts (i.e, `limesurvey-php` and `limesurvey-postgresql`), you may need to run the following command to update the dependencies:

```bash
helm dependency update
```

To delete a deployment, and remove all the Helm created elements:

```zsh
helm uninstall limesurvey
```

This will _not_ remove the persistent volume claim (PVC) associated with the PostgreSQL database. You may need to delete it manually if it is no longer needed.

## Vault / Secret Management

This project assumes the use of HashiCorp Vault for managing secrets. You will need to configure your Vault instance and set the appropriate environment variables for your deployment. See the [Vault Getting Started Guide](https://developer.gov.bc.ca/docs/default/component/platform-developer-docs/docs/secrets-management/vault-getting-started-guide/) for more information.
You may also set these environment variables on your deployment via environment variables, but this is not recommended for production environments. Simply set the values below in your deployment configuration or a mounted Secret instead of in Vault.

### Vault - Values to populate

This deployment uses two Vault secrets with a few values each.  
In dev, secrets are expected at `cd77be-nonprod/dev/<name>`  
In test, secrets are expected at `cd77be-nonprod/test/<name>`  
In prod, secrets are expected at `cd77be-nonprod/<name>`

The two secrets are `postgres` and `limesurvey`.

#### Values for `limesurvey`

`ADMIN_USER`: The username of the admin user for LimeSurvey.  
`ADMIN_PASSWORD`: The password for the admin user for LimeSurvey.  
`ADMIN_EMAIL`: The email address of the admin user for LimeSurvey.  
`ADMIN_FULLNAME`: The full name of the admin user for LimeSurvey.

#### Values for `postgres`

`PGUSER`: The username for the PostgreSQL database. Will be created automatically.  
`PGPASSWORD`: The password for the created user.  
`POSTGRES_PASSWORD`: The password for the admin PostgreSQL user.

### Vault - Setup

Vault settings have been parameterized out into the `vault` section of the `values.yaml` file. You will need to update these settings to match your Vault instance configuration.
Some values are environment-specific and will instead be found in `values-<environment>.yaml` (See Helm section for more information).

```yaml
# Ensure you are setting `global.vault.*`, not `vault.*`
global:
  vault:
    # If false, secrets will not be fetched from Vault. You will need to manage them yourself.
    enabled: true
    # This is always platform-services on BC Gov Openshift
    namespace: platform-services
    # Must match the cluster. Use one of:
    # auth/k8s-silver, auth/k8s-gold, auth/k8s-golddr, auth/k8s-emerald
    authPath: "auth/k8s-silver"
    # Follows pattern <licenseplate>-vault
    serviceAccount: cd77be-vault
    # Options are <licenseplate>-nonprod or <licenseplate>-prod
    engine: cd77be-nonprod
    # Path to the secret root within the Vault.
    # Used to store "dev" and "test" secrets in the same vault.
    # path: test/
    # path: '' # No path in prod - prod secrets are stored at the root
    path: dev/
```
