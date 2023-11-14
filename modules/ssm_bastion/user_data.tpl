#! /bin/bash

set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
mkdir /opt/keypull/
cat > /opt/keypull/key-fetch-cron.sh <<"EOF"
#!/bin/bash
set -x
exec > >(tee /var/log/key-fetch-cron.log|logger -t key-fetch-cron ) 2>&1
export KEY_BUCKET=$(aws s3 ls | xargs -n1 echo | grep ${PublicKeysBucket})
echo "Key bucket is $KEY_BUCKET"
head -2 ~ec2-user/.ssh/authorized_keys > /tmp/authorized_keys
# only append s3 public keys if there are any
bucket_contents=`aws s3 ls s3://$KEY_BUCKET/`
if [[ ! -z "$bucket_contents" ]]; then
    aws s3 ls s3://$KEY_BUCKET | xargs -n1 echo | grep .pub | xargs -n1 -I {} aws s3  cp s3://$KEY_BUCKET/{} - >> /tmp/authorized_keys
    cp /tmp/authorized_keys ~ec2-user/.ssh/authorized_keys
fi
EOF
chmod ug+x /opt/keypull/key-fetch-cron.sh
# Add Line to crontab in 5 minutes to allow other stuff to propogate
echo "(crontab -l; echo '*/10 * * * * /opt/keypull/key-fetch-cron.sh' ) | crontab" | at now + 5 minutes
echo "done"
