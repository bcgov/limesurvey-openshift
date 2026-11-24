FROM nginx:1.31.9@sha256:84f7876d21d154885f99554d7ae325d8c2213f9169726ea7ab60642f2573a787

ENV ROOT_DIR="/var/www/html"
ENV RELEASE="7.11.0+261116.zip"
ENV LIMESURVEY_SHA256="cf2df8f0269bfdf9aab10ee4da83b7e259ca3dc854da89ba570669f3c0d9985f"

# Install the GNU Compiler Collection
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl pv unzip \
    #&& apt-get install -y gcc mono-mcs \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/conf.d/default.conf \
    # Create the necessary directories
    && mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/scgi_temp \
    /var/cache/nginx/uwsgi_temp

# Add debugging tools into builds if enabled
ARG DEBUG_BUILD=false

RUN if [ ${DEBUG_BUILD} = true ]; then \
  apt update && apt-get install --no-install-recommends -y jq vim procps iputils-ping less; \
fi

# Create all necessary temp and cache directories
RUN mkdir -p /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp /tmp/cache/nginx \
    && chmod -R 777 /tmp/client_temp /tmp/proxy_temp /tmp/fastcgi_temp /tmp/uwsgi_temp /tmp/scgi_temp /tmp/cache/nginx

# Copy the NGINX configuration files
COPY nginx.conf /etc/nginx
RUN mkdir -p /var/www/html/

RUN echo "LimeSurvey not found, downloading..." && \
    curl --fail --location --silent --show-error "https://download.limesurvey.org/latest-master/limesurvey${RELEASE}" -o /tmp/limesurvey.zip && \
    echo "${LIMESURVEY_SHA256}  /tmp/limesurvey.zip" | sha256sum -c - && \
    unzip -o /tmp/limesurvey.zip -d "$ROOT_DIR" | pv -lf -s "$(unzip -l /tmp/limesurvey.zip | wc -l)" > /dev/null && \
    rm -f /tmp/limesurvey.zip && \
    find "$ROOT_DIR/limesurvey/editor" -mindepth 1 -maxdepth 1 ! -name 'build' ! -name "index.html" -exec rm -rf {} + && \
    echo "LimeSurvey downloaded and extracted."

# Claim ownership for the NGiNX user
RUN chown -R nginx:nginx /usr/share/nginx /var/log/nginx /var/cache/nginx /var/www/html /etc/nginx
USER nginx