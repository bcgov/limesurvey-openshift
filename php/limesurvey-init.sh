#!/bin/bash
set -euo pipefail

ROOT_DIR="/var/www/html"
MEMCACHED_HOST="${MEMCACHED_HOST:-limesurvey-memcached}"

# PostgreSQL defaults
PGHOST="${PGHOST:-limesurvey-postgresql}"
PGPORT="${PGPORT:-5432}"
PGDATABASE="${PGDATABASE:-limesurvey}"

## No defaults so we crash when not set
# MSSQL defaults
#DB_HOST="${DB_HOST:-}"
#DB_PORT="${DB_PORT:-1433}"
#DB_NAME="${DB_NAME:-limesurvey}"
#DB_USER="${DB_USER:-sa}"
#DB_PASSWORD="${DB_PASSWORD:-}"

CURRENT_STEP=1
TOTAL_STEPS=$(grep -c '^print_step' "${BASH_SOURCE[0]}")
function print_step {
  local LIGHT="\033[1;32m"
  local RESET="\033[0m"
if [[ -z "$1" ]]; then
    echo -e "${LIGHT}[Step $CURRENT_STEP/$TOTAL_STEPS]${RESET}"
  else
    echo -e "${LIGHT}[Step $CURRENT_STEP/$TOTAL_STEPS]${RESET} $1"
  fi
  CURRENT_STEP=$((CURRENT_STEP + 1))
}

echo "=== Initializing Limesurvey ==="

print_step "Checking for LimeSurvey installation..."

  CONFIG_FILE="$ROOT_DIR/limesurvey/application/config/email.php"
  mkdir -p "$ROOT_DIR/limesurvey/tmp/runtime" "$ROOT_DIR/limesurvey/tmp/assets" "$ROOT_DIR/limesurvey/tmp/files"
  mkdir -p "$ROOT_DIR/limesurvey/upload/admintheme" "$ROOT_DIR/limesurvey/upload/global" "$ROOT_DIR/limesurvey/upload/labels" "$ROOT_DIR/limesurvey/upload/plugins" "$ROOT_DIR/limesurvey/upload/surveys" "$ROOT_DIR/limesurvey/upload/themes" "$ROOT_DIR/limesurvey/upload/themes/survey" "$ROOT_DIR/limesurvey/upload/twig"

  ADMIN_FULLNAME="${ADMIN_FULLNAME:-Administrator}"
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"

  sed -i "s|^\(\$config\['siteadminemail'\]\s*=\s*\).*|\1'$ADMIN_EMAIL';|" "$CONFIG_FILE"
  sed -i "s|^\(\$config\['siteadminbounce'\]\s*=\s*\).*|\1'$ADMIN_EMAIL';|" "$CONFIG_FILE"
  sed -i "s|^\(\$config\['siteadminname'\]\s*=\s*\).*|\1'$ADMIN_FULLNAME';|" "$CONFIG_FILE"
fi

print_step "Email configuration updated in $CONFIG_FILE."

print_step "Verifying database connection and table status..."

# Use PHP to parse the generated config.php and check table existence.
# This ensures we use the exact connection string LimeSurvey will use,
# and allows us to distinguish between connection failure and an empty DB.
TABLES_EXIST=$(php -r "
  try {
    // Satisfy LimeSurvey's internal security check to allow direct import
    define('BASEPATH', true);
    
    // Load the exact config Limesurvey generated/uses
    \$config = require('$ROOT_DIR/limesurvey/application/config/config.php');
    \$db = \$config['components']['db'];
    
    // Connect using Limesurvey's own connection string
    \$pdo = new PDO(\$db['connectionString'], \$db['username'], \$db['password']);
    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if tables already exist
    \$result = \$pdo->query(\"SELECT COUNT(*) FROM information_schema.tables WHERE table_type='BASE TABLE'\");
    \$count = \$result->fetchColumn();
    echo (\$count > 0) ? 'true' : 'empty';
  } catch (Exception \$e) {
    // Return 'error' instead of 'empty' so we don't try to install against a broken connection
    echo 'error';
  }
" || echo 'error')

  if [[ "$TABLES_EXIST" == "empty" ]]; then
    echo "Setting up LimeSurvey database..."
    cd "$ROOT_DIR/limesurvey/application/commands"

    if [[ -z "${ADMIN_PASSWORD:-}" ]]; then
      echo "ADMIN_PASSWORD must be supplied through secret management before the first installation."
      exit 1
    fi

    echo "Completing LimeSurvey installation..."
    php "$ROOT_DIR/limesurvey/application/commands/console.php" install "${ADMIN_USER:-admin}" "$ADMIN_PASSWORD" "$ADMIN_FULLNAME" "$ADMIN_EMAIL"
  elif [[ "$TABLES_EXIST" == "true" ]]; then
    echo "Database appears to be initialized."
    echo "Checking for and applying database updates..."
    php "$ROOT_DIR/limesurvey/application/commands/console.php" updatedb
  else
    echo "Error checking database tables. Output was: $TABLES_EXIST"
    exit 1
  fi
fi

print_step "Initial setup tasks completed."
echo "LimeSurvey is ready to launch."
echo "=== Exiting init script ==="
exit 0