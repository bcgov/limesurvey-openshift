#!/bin/bash
set -euo pipefail
cd docker

docker build --file nginx/Dockerfile --tag limesurvey-openshift/nginx:latest ./nginx
docker build --file php/Dockerfile --tag limesurvey-openshift/php:latest ./php

