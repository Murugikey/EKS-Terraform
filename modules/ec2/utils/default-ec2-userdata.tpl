MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    # Environments
    export PATH=$PATH:/usr/local/bin
    export PROJECT=${PROJECT}

    echo "SSM AGENT INSTALLATION"

    yum install -y amazon-ssm-agent

    echo "SSM AGENT STARTING UP"

    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent

    sudo yum -y install nfs-utils