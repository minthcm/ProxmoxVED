#!/usr/bin/env bash

# Copyright (c) 2021-2025 minthcm
# Author: MintHCM
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/minthcm/minthcm
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.2"
PHP_APACHE="YES" PHP_MODULE="mysql,cli,redis" PHP_FPM="YES" setup_php
setup_composer

msg_info "Enabling Apache modules (rewrite, headers)"
$STD a2enmod rewrite
$STD a2enmod headers
msg_ok "Enabled Apache modules (rewrite, headers)"

fetch_and_deploy_gh_release "MintHCM" "minthcm/minthcm" "tarball" "latest" "/var/www/MintHCM"

msg_info "Configuring MintHCM"
mkdir -p /etc/php/${PHP_VERSION}/mods-available
cp /var/www/MintHCM/docker/config/000-default.conf /etc/apache2/sites-available/000-default.conf
cp /var/www/MintHCM/docker/config/php-minthcm.ini /etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini
mkdir -p "/etc/php/${PHP_VERSION}/cli/conf.d" "/etc/php/${PHP_VERSION}/apache2/conf.d"
ln -s "/etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/20-minthcm.ini"
ln -s "/etc/php/${PHP_VERSION}/mods-available/php-minthcm.ini" "/etc/php/${PHP_VERSION}/apache2/conf.d/20-minthcm.ini"
chown -R www-data:www-data /var/www/MintHCM
find /var/www/MintHCM -type d -exec chmod 755 {} \;
find /var/www/MintHCM -type f -exec chmod 644 {} \;
msg_ok "Configured MintHCM"

msg_info "Restarting Apache2"
$STD systemctl restart apache2
msg_ok "Restarted Apache2"
printf "*    *    *    *    *     cd /var/www/MintHCM/legacy; php -f cron.php > /dev/null 2>&1\n" > /var/spool/cron/crontabs/www-data
service cron start
rm -f /var/www/MintHCM/configMint4
msg_ok "Installed MintHCM"

motd_ssh
customize
cleanup_lxc
