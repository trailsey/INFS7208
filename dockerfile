FROM ubuntu:18.04 AS base

# Labels included in next stage

ARG PHPVER=7.4

#Install and setup NginX and PHP
RUN apt-get update \
    && apt-get install --no-install-recommends \
                        --no-install-suggests -qqy \
                        apt-transport-https \
                        apt-utils \
                        autoconf \
                        ca-certificates \
                        curl \
                        dirmngr \
                        gcc \
                        gnupg2 \
                        libc-dev \
                        lsb-release \
                        make \
                        pkg-config \
                        software-properties-common \
                        wget \
                        zlib1g-dev

RUN export DEBIAN_FRONTEND=noninteractive \
    && add-apt-repository ppa:ondrej/php -y \
    && apt-get update \
    && apt-get install --no-install-recommends \
                        --no-install-suggests -qqy \
                        nginx \
                        php${PHPVER} \
                        php${PHPVER}-bcmath \
                        php${PHPVER}-cli \
                        php${PHPVER}-curl \
                        php${PHPVER}-fpm \
                        php${PHPVER}-gd \
                        php${PHPVER}-json \
                        php${PHPVER}-json \
                        php${PHPVER}-mbstring \
                        php${PHPVER}-pdo \
                        php${PHPVER}-pgsql \
                        php${PHPVER}-xml \
                        php${PHPVER}-zip \
    && sed -i -e "s/pid =.*/pid = \/var\/run\/php${PHPVER}-fpm.pid/" \
        /etc/php/${PHPVER}/fpm/php-fpm.conf \
    && sed -i -e "s/error_log =.*/error_log = \/proc\/self\/fd\/2/" \
        /etc/php/${PHPVER}/fpm/php-fpm.conf \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" \
        /etc/php/${PHPVER}/fpm/php-fpm.conf \
    && sed -i "s/listen = .*/listen = 127.0.0.1:9000/" \
        /etc/php/${PHPVER}/fpm/pool.d/www.conf \
    && sed -i "56,63d" /etc/nginx/sites-enabled/default \ 
    && sed -i "56i\\\tlocation ~ \\\.php$ {" /etc/nginx/sites-enabled/default \
    && sed -i "57i\\\t\ttry_files \$uri \$uri/ /index.php?\$query_string;" /etc/nginx/sites-enabled/default \
    && sed -i "58i\\\t\tfastcgi_split_path_info ^(.+\\\.php)(/.+)$;" /etc/nginx/sites-enabled/default \
    && sed -i "59i\\\t\tfastcgi_pass 127.0.0.1:9000;" /etc/nginx/sites-enabled/default \
    && sed -i "60i\\\t\tfastcgi_index index.php;" /etc/nginx/sites-enabled/default \
    && sed -i "61i\\\t\tinclude fastcgi_params;" /etc/nginx/sites-enabled/default \
    && sed -i "62i\\\t\tfastcgi_param SCRIPT_FILENAME /var/www/html\$fastcgi_script_name;" /etc/nginx/sites-enabled/default \
    && sed -i "63i\\\t\tfastcgi_param PATH_INFO \$fastcgi_path_info;\n\t}" /etc/nginx/sites-enabled/default \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -s /etc/init.d/php${PHPVER}-fpm /sbin/php-fpm \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && apt-get autoremove    

EXPOSE 80 443

FROM scratch
LABEL name="Troy Stephenson" \
    email="troy.stephenson@uqconnect.edu.au"
COPY --from=base . .
CMD php-fpm restart && nginx -g "daemon off;"