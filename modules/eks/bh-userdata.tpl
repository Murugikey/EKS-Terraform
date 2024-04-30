MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -o xtrace

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

    # Environments
    export PATH=$PATH:/usr/local/bin
    export REGION=${REGION}
    export PROJECT=${PROJECT}
    export CLUSTER=${CLUSTER_NAME}
    export CLOUDWATCHGROUP=wit-cw
    export KUBECTL_VERSION="v1.23.6"

    yum install -y amazon-ssm-agent
    systemctl enable amazon-ssm-agent && systemctl start amazon-ssm-agent
    
    # Utils
    yum install ec2-net-utils git zsh -y
    
    # AWS CLI Install
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    aws configure set region $REGION

    # Eksctl install
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    mv /tmp/eksctl /usr/local/bin
    ln -s /usr/local/bin/eksctl /usr/bin/
        
    ## Kubectl install    
    #curl -LO "https://dl.k8s.io/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    #install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    #ln -s /usr/local/bin/kubectl /usr/bin/
    #export K8_VERSION=$(kubectl version --short --client)
    
    # KubeConfig install
    aws eks update-kubeconfig --region $REGION --name $CLUSTER
    
    # ArgoCD CLI install
    unixVERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/$unixVERSION/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
    ln -s /usr/local/bin/argocd /usr/bin/

    # OhMyZsh Install and plugins
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git /root/.oh-my-zsh/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/plugins/zsh-syntax-highlighting
    sed -i 's/(git)/(git zsh-autosuggestions zsh-syntax-highlighting)/g' /root/.zshrc

    # Kubectl install    
    curl -LO "https://dl.k8s.io/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    ln -s /usr/local/bin/kubectl /usr/bin/
    export K8_VERSION=$(kubectl version --short --client)
    
--//--