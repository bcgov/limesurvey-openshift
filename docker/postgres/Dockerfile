FROM postgres:latest

# Claim ownership for the www-data user
RUN chown -R www-data:www-data /var/run/postgresql

# Set the default working directory
WORKDIR /var/lib/postgresql