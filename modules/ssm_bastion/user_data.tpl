#!/bin/bash

set -x
exec > >(tee /var/log/user-data.log|logger -t user-data ) 2>&1
mkdir /opt/keypull/

cat > /opt/keypull/key-fetch.sh <<"EOF"
#!/bin/bash
set -x
exec > >(tee /var/log/key-fetch.log|logger -t key-fetch ) 2>&1
export KEY_BUCKET=$(aws s3 ls | xargs -n1 echo | grep ${PublicKeysBucket})
head -2 ~ec2-user/.ssh/authorized_keys > /tmp/authorized_keys
bucket_contents=`aws s3 ls s3://$KEY_BUCKET/ --region ${AWSRegion}`
if [[ ! -z "$bucket_contents" ]]; then
    aws s3 ls s3://$KEY_BUCKET --region ${AWSRegion} | xargs -n1 echo | grep .pub | xargs -n1 -I {} aws s3  cp s3://$KEY_BUCKET/{} --region ${AWSRegion} - >> /tmp/authorized_keys
    cp /tmp/authorized_keys ~ec2-user/.ssh/authorized_keys
fi
EOF

chmod ug+x /opt/keypull/key-fetch.sh
echo "(crontab -l; echo '*/10 * * * * /opt/keypull/key-fetch.sh' ) | crontab" | at now + 5 minutes
