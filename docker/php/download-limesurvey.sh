#!/bin/bash
set -e p

LIMESURVEY_DIR="/var/www/html/limesurvey"
LOCKFILE="$LIMESURVEY_DIR/.limesurvey_downloaded.lock"
RELEASE="${LIMESURVEY_RELEASE:-6.15.5+250724.zip}"

if [ ! -f "$LOCKFILE" ]; then
  echo "LimeSurvey not found, downloading..."
  mkdir -p "$LIMESURVEY_DIR"
  curl -L "https://download.limesurvey.org/latest-master/limesurvey${RELEASE}" -o /tmp/limesurvey.zip
  unzip -q /tmp/limesurvey.zip -d /var/www/html
  rm -f /tmp/limesurvey.zip
  touch "$LOCKFILE"
  echo "LimeSurvey downloaded and extracted."
else
  echo "LimeSurvey already present, skipping download."
fi
