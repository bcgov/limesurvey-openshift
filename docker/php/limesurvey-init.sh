#!/bin/bash
set -e p

LIMESURVEY_DIR="/var/www/html/limesurvey"
LOCKFILE="$LIMESURVEY_DIR/.limesurvey_downloaded.lock"
RELEASE="${LIMESURVEY_RELEASE:-6.15.5+250724.zip}"

if [ ! -f "$LOCKFILE" ]; then
  echo "LimeSurvey not found, downloading..."
  curl -L "https://download.limesurvey.org/latest-master/limesurvey${RELEASE}" -o /tmp/limesurvey.zip
  echo "Download completed, extracting... (this may take a moment)"
  unzip -o /tmp/limesurvey.zip -d "$LIMESURVEY_DIR" | pv -l -s $(unzip -l /tmp/limesurvey.zip | wc -l)
  echo "Unzip completed, cleaning up..."
  rm -f /tmp/limesurvey.zip
  echo "Creating lock file to prevent re-download..."
  touch $LOCKFILE
  echo "LimeSurvey downloaded and extracted."
else
  echo "LimeSurvey already present, skipping download."
fi

# Start the PHP-FPM service
echo "Starting PHP-FPM service..."
exec docker-php-entrypoint php-fpm