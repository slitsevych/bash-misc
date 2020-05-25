#!/usr/bin/env bash

function main {
cat << EOF > /etc/systemd/system/logs-shutdown.service
[Unit]
Description=Archive logs before shutdown
After=network.target

[Service]
RemainAfterExit=yes
ExecStop=/bin/bash /root/logs_shutdown.sh

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /root/logs_shutdown.sh

export HOSTNAME=\$(hostname)
export INSTANCE_ID=\$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
export LOG_FILE=\$HOSTNAME.logs.\$(date +%F_%R).tar.gz
export REGION_SRC=\$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep -oP '\"region\"[[:space:]]*:[[:space:]]* \"\K[^\"]+')
export REGION_DEST="us-east-1"
export BUCKET="mybucket"

mkdir -p /tmp/logs
cp -R /var/log/ /tmp/logs
tar -czvf /tmp/\$LOG_FILE /tmp/logs

aws s3 cp /tmp/\$LOG_FILE s3://\$BUCKET/\$REGION_SRC/\$INSTANCE_ID/ --region \$REGION_DEST
EOF

chmod 755 /root/logs_shutdown.sh
systemctl start logs-shutdown.service
systemctl enable logs-shutdown.service
}

main