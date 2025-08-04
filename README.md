# LimeSurvey

Deploy a LimeSurvey instance leveraging Docker and Helm.

## Credits

This project is based on the work of [Byron Stuike](https://github.com/farghul), who created an initial version of this project using Podman and Ansible. The original work was licensed under the Unlicense. This version has been adapted for use with Docker and Helm, and is licensed under the Apache License 2.0.

![LimeSurvey logo](limesurvey.svg)

## Prerequisites

The following items are necessary for a successful deployment.

## Docker

Individually, the images can be built, tagged, and pushed to a container registry.

```zsh
docker build --file Dockerfile --tag [name] .

docker image tag [name]:latest [repo]/[name]:[version]

docker push [repo]/[name]:[version]
```

## Helm

Adjust the necessary entries in the `helm/charts/values.yaml` file to target the correct namespace and use the desired host name.

```yaml
global:
  licensePlate: cd77be
  sectionTag: -dev
  replicaCount: 1
  image:
    repository: image-registry.openshift-image-registry.svc:5000/
    imageStreamTag: latest
  host: "deseng-limesurvey-dev.apps.silver.devops.gov.bc.ca"
```

To manually trigger a deployment, navigate to the `helm` folder and run:

```zsh
helm install limesurvey .
```

To update a deployment, edit the Helm charts as necessary and run:

```zsh
helm upgrade limesurvey .
```

To delete a deployment, and remove all the Helm created elements:

```zsh
helm uninstall limesurvey
```

Note: oc-cli login via token required to use helm

```zsh
oc login --server=https://api.silver.devops.gov.bc.ca:6443
```
