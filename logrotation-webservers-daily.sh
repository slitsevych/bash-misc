#!/usr/bin/env bash
#############
# Functions #
#############

function main {

VARS=`curl -s http://169.254.169.254/latest/user-data`
IFS=', ' read -r -a array <<< $VARS
ENV_BRANCH=${array[1]}

SERVICE_TYPE="webservers"
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION_SRC=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '\"region\"[[:space:]]*:[[:space:]]* \"\K[^\"]+')

case $ENV_BRANCH in
        DEV)
            ENV_LOGROTATE="dev"
        ;;
        STAGE)
            ENV_LOGROTATE="stage"
        ;;
        PROD)
            ENV_LOGROTATE="prod"
        ;;
        *)
            ENV_LOGROTATE="dev"
        ;;
esac

cat <<EOF > /etc/cron.daily/logrotate
#!/bin/sh
/usr/bin/find /var/log/ -type f -name "*.gz" -mtime +7 -exec rm -fv {} \;
/usr/sbin/logrotate /etc/logrotate.conf
EOF

mv /etc/cron.daily/logrotate /etc/cron.hourly/
service cron restart

logrotate_syslog
logrotate_nginx_php_fpm
}

function logrotate_nginx_php_fpm {
if [[ -f /etc/logrotate.d/php-fpm-7.0 ]]; then rm -f /etc/logrotate.d/php-fpm-7.0; fi
if [[ -f /etc/logrotate.d/nginx ]]; then rm -f /etc/logrotate.d/nginx; fi
if [[ -f /etc/logrotate.d/nginx.rpmnew ]]; then rm -f /etc/logrotate.d/nginx.rpmnew; fi

if ! [[ -f /etc/logrotate.d/nginx-php-fpm-s3 ]]; then
    touch /etc/logrotate.d/nginx-php-fpm-s3
    cat <<EOF > /etc/logrotate.d/nginx-phpfpm-s3
/var/log/php-fpm/7.0/*log {
daily
size 10M
missingok
notifempty
rotate 4
maxage 4
sharedscripts
compress
copytruncate
dateext
dateformat -%Y%m%d-%H:%M:%S
postrotate
    /bin/kill -SIGUSR1 `cat /var/run/php-fpm/php-fpm-7.0.pid 2>/dev/null` 2>/dev/null || true
endscript
lastaction
    INSTANCE_ID=`echo ${INSTANCE_ID}`
    HOSTNAME=`hostname`
    BUCKET=`echo ${ENV_LOGROTATE}`-logs
    SERVICE_TYPE=`echo ${SERVICE_TYPE}`
    REGION_SRC=`echo ${REGION_SRC}`
    REGION_DEST=us-east-1
    read DAY MONTH YEAR <<< `date "+%d %m %Y"`
    FORMAT=`date "+%Y%m%d-%H:%M:%S"` 
    aws s3 sync /var/log/php-fpm/7.0/ "s3://\$BUCKET/\$REGION_SRC/\$SERVICE_TYPE/\${HOSTNAME}_\${INSTANCE_ID}/php-fpm/\$YEAR/\$MONTH/\$DAY/" --region \$REGION_DEST --exclude "*" --include "*.log-\$FORMAT*"
endscript
}

/var/log/nginx/*.log {
daily
size 10M
missingok
notifempty
rotate 4
maxage 4
sharedscripts
compress
copytruncate
dateext
dateformat -%Y%m%d-%H:%M:%S
postrotate
    /etc/init.d/nginx reopen_logs
endscript
lastaction
    INSTANCE_ID=`echo ${INSTANCE_ID}`
    HOSTNAME=`hostname`
    BUCKET=`echo ${ENV_LOGROTATE}`-logs
    SERVICE_TYPE=`echo ${SERVICE_TYPE}`
    REGION_SRC=`echo ${REGION_SRC}`
    REGION_DEST=us-east-1
    read DAY MONTH YEAR <<< `date "+%d %m %Y"`
    FORMAT=`date "+%Y%m%d-%H:%M:%S"`
    aws s3 sync /var/log/nginx/ "s3://\$BUCKET/\$REGION_SRC/\$SERVICE_TYPE/\${HOSTNAME}_\${INSTANCE_ID}/nginx/\$YEAR/\$MONTH/\$DAY/" --region \$REGION_DEST --exclude "*" --include "*.log-\$FORMAT*"
endscript
}
EOF
fi
}

function logrotate_syslog {
if [[ -f /etc/debian_version ]]; then 
    if [[ `cat /etc/logrotate.d/rsyslog | grep "/var/log/syslog" | wc -l` == 1 ]]; then
        sed -i 's/syslog/syslog-old/g' /etc/logrotate.d/rsyslog
    fi
    if ! [[ -f /etc/logrotate.d/syslog-s3 ]]; then
        touch /etc/logrotate.d/syslog-s3
        cat <<EOF > /etc/logrotate.d/syslog-s3
/var/log/syslog {
daily
size 10M
missingok
notifempty
rotate 4
maxage 4
sharedscripts
compress
copytruncate
dateext
dateformat -%Y%m%d-%H:%M:%S
postrotate
    reload rsyslog >/dev/null 2>&1 || true
endscript
lastaction
    INSTANCE_ID=`echo ${INSTANCE_ID}`
    HOSTNAME=`hostname`
    BUCKET=`echo ${ENV_LOGROTATE}`-logs
    SERVICE_TYPE=`echo ${SERVICE_TYPE}`
    REGION_SRC=`echo ${REGION_SRC}`
    REGION_DEST=us-east-1
    read DAY MONTH YEAR <<< `date "+%d %m %Y"`
    FORMAT=`date "+%Y%m%d-%H:%M:%S"` 
    aws s3 sync /var/log/ "s3://\$BUCKET/\$REGION_SRC/\$SERVICE_TYPE/\$INSTANCE_ID/syslog\$YEAR/\$MONTH/\$DAY/" --region \$REGION_DEST --exclude "*" --include "syslog-\$FORMAT*"
endscript
}
}
EOF
    fi
elif ! [[ -f /etc/debian_version ]]; then
    if [[ `cat /etc/logrotate.d/syslog | grep "/var/log/messages" | wc -l` == 1 ]] ; then
        sed -i '/messages/d' /etc/logrotate.d/syslog 
    fi
    if ! [[ -f /etc/logrotate.d/syslog-s3 ]]; then
        touch /etc/logrotate.d/syslog-s3
        cat <<EOF > /etc/logrotate.d/syslog-s3
/var/log/messages {
daily
size 10M
missingok
notifempty
rotate 4
maxage 4
sharedscripts
compress
copytruncate
dateext
dateformat -%Y%m%d-%H:%M:%S
postrotate
    /bin/kill -HUP 'cat /var/run/syslogd.pid 2> /dev/null' 2> /dev/null || true
endscript
lastaction
    INSTANCE_ID=`echo ${INSTANCE_ID}`
    HOSTNAME=`hostname`
    BUCKET=`echo ${ENV_LOGROTATE}`-logs
    SERVICE_TYPE=`echo ${SERVICE_TYPE}`
    REGION_SRC=`echo ${REGION_SRC}`
    REGION_DEST=us-east-1
    read DAY MONTH YEAR <<< `date "+%d %m %Y"`
    FORMAT=`date "+%Y%m%d-%H:%M:%S"` 
    aws s3 sync /var/log/ "s3://\$BUCKET/\$REGION_SRC/\$SERVICE_TYPE/\$INSTANCE_ID/messages\$YEAR/\$MONTH/\$DAY/" --region \$REGION_DEST --exclude "*" --include "messages-\$FORMAT*"
endscript
}
EOF
    fi
fi
}

#########
# Main #
########

main