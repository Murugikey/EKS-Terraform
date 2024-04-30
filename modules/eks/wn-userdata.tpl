MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent

    #!/bin/bash

    B64_CLUSTER_CA=${B64_CLUSTER_CA}
    API_SERVER_URL=${API_SERVER_URL}
    NODE_GROUP_NAME=${NODE_GROUP_NAME}
    CAPACITY=${CAPACITY}
    EC2_AMI=${EC2_AMI}

    LABELS="--node-labels=eks.amazonaws.com/nodegroup-image=$EC2_AMI,eks.amazonaws.com/capacityType=${CAPACITY},eks.amazonaws.com/nodegroup=${NODE_GROUP_NAME}"
    
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} --kubelet-extra-args $LABELS --b64-cluster-ca $B64_CLUSTER_CA --apiserver-endpoint $API_SERVER_URL

--//--