#!/bin/bash

# Disable Strict Host checking for non interactive git clones

mkdir -p -m 0700 /root/.ssh
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

if [ ! -z "$SSH_KEY" ]; then
 echo $SSH_KEY > /root/.ssh/id_rsa.base64
 base64 -d /root/.ssh/id_rsa.base64 > /root/.ssh/id_rsa
 chmod 600 /root/.ssh/id_rsa
fi

# Set custom webroot
if [ ! -z "$WEBROOT" ]; then
  webroot=$WEBROOT
  sed -i "s#root /var/www/html;#root ${webroot};#g" /etc/nginx/sites-available/default.conf
else
  webroot=/var/www/html
fi

# Setup git variables
if [ ! -z "$GIT_EMAIL" ]; then
 git config --global user.email "$GIT_EMAIL"
fi
if [ ! -z "$GIT_NAME" ]; then
 git config --global user.name "$GIT_NAME"
 git config --global push.default simple
fi

# Dont pull code down if the .git folder exists
if [ ! -d "/var/www/html/.git" ]; then
 # Pull down code from git for our site!
 if [ ! -z "$GIT_REPO" ]; then
   # Remove the test index file
   rm -Rf /var/www/html/index.php
   if [ ! -z "$GIT_BRANCH" ]; then
     git clone -b $GIT_BRANCH $GIT_REPO /var/www/html
   else
     git clone $GIT_REPO /var/www/html
   fi
 fi
fi

# Display PHP error's or not
if [[ "$ERRORS" != "1" ]] ; then
 echo php_flag[display_errors] = off >> /etc/php7/php-fpm.conf
else
 echo php_flag[display_errors] = on >> /etc/php7/php-fpm.conf
fi

# Enable PHP short tag or not
if [[ "$SHORT_TAG" != "1" ]] ; then
 echo php_flag[short_open_tag] = off >> /etc/php7/php-fpm.conf
else
 echo php_flag[short_open_tag] = on >> /etc/php7/php-fpm.conf
fi

# Display Version Details or not
if [[ "$HIDE_NGINX_HEADERS" == "0" ]] ; then
 sed -i "s/server_tokens off;/server_tokens on;/g" /etc/nginx/nginx.conf
else
 sed -i "s/expose_php = On/expose_php = Off/g" /etc/php7/conf.d/php.ini
fi

# Enable proxy for Docker-Hook at /docker-hook/
if [[ "$DOCKER_HOOK_PROXY" != "1" ]] ; then
 sed -i '/location \/docker-hook/,/.*\}/d' /etc/nginx/sites-available/default.conf
 sed -i '/location \/docker-hook/,/.*\}/d' /etc/nginx/sites-available/default-ssl.conf
fi

# Increase the memory_limit
if [ ! -z "$PHP_MEM_LIMIT" ]; then
 sed -i "s/memory_limit = 128M/memory_limit = ${PHP_MEM_LIMIT}M/g" /etc/php7/conf.d/php.ini
fi

# Increase the post_max_size
if [ ! -z "$PHP_POST_MAX_SIZE" ]; then
 sed -i "s/post_max_size = 100M/post_max_size = ${PHP_POST_MAX_SIZE}M/g" /etc/php7/conf.d/php.ini
fi

# Increase the upload_max_filesize
if [ ! -z "$PHP_UPLOAD_MAX_FILESIZE" ]; then
 sed -i "s/upload_max_filesize = 100M/upload_max_filesize= ${PHP_UPLOAD_MAX_FILESIZE}M/g" /etc/php7/conf.d/php.ini
fi


# Customize the php-fpm server configurations
if [ ! -z "$PM_START_SERVERS" ]; then
 sed -i "s/pm.start_servers =.*/pm.start_servers = ${PM_START_SERVERS}/g" /etc/php7/php-fpm.d/www.conf
fi

if [ ! -z "$PM_MIN_SPARE_SERVERS" ]; then
 sed -i "s/pm.min_spare_servers =.*/pm.min_spare_servers = ${PM_MIN_SPARE_SERVERS}/g" /etc/php7/php-fpm.d/www.conf
fi

if [ ! -z "$PM_MAX_SPARE_SERVERS" ]; then
 sed -i "s/pm.max_spare_servers =.*/pm.max_spare_servers = ${PM_MAX_SPARE_SERVERS}/g" /etc/php7/php-fpm.d/www.conf
fi

if [ ! -z "$PM_MAX_REQUESTS" ]; then
 sed -i "s/pm.max_requests =.*/pm.max_requests = ${PM_MAX_REQUESTS}/g" /etc/php7/php-fpm.d/www.conf
fi

if [ ! -z "$PM_MAX_CHILDREN" ]; then
 sed -i "s/pm.max_children =.*/pm.max_children = ${PM_MAX_CHILDREN}/g" /etc/php7/php-fpm.d/www.conf
fi


if [[ "$HTTPS_REDIRECT" == "0" ]] ; then
 sed -i "s/if \(\$http_x_forwarded_protolocation/\#/g" /etc/nginx/sites-available/default.conf
fi

# Always chown webroot for better mounting
chown -Rf nginx.nginx /var/www/html

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
