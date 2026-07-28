FROM nginx:1@sha256:5a88c9c45479443d7be2eadc894b4ed0a9801bae03d97a5760ae13b5c2005942

ENV ROOT_DIR="/var/www/html"
ENV RELEASE="7.0.0-RC1+260430.zip"
ENV LIMESURVEY_SHA256="765cb6498d96f41a52610920dcec6b389f3f8dcc0290615b8df6520ccf99776b"

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
    curl --fail --location --silent --show-error "https://download.limesurvey.org/latest-develop-major/limesurvey${RELEASE}" -o /tmp/limesurvey.zip && \
    echo "${LIMESURVEY_SHA256}  /tmp/limesurvey.zip" | sha256sum -c - && \
    unzip -o /tmp/limesurvey.zip -d "$ROOT_DIR" | pv -lf -s "$(unzip -l /tmp/limesurvey.zip | wc -l)" > /dev/null && \
    rm -f /tmp/limesurvey.zip && \
    find "$ROOT_DIR/limesurvey/editor" -mindepth 1 -maxdepth 1 ! -name 'build' ! -name "index.html" -exec rm -rf {} + && \
    echo "LimeSurvey downloaded and extracted."

# Claim ownership for the NGiNX user
RUN chown -R nginx:nginx /usr/share/nginx /var/log/nginx /var/cache/nginx /var/www/html /etc/nginx
USER nginx