provider "helm" {
  alias = "connect"
  kubernetes {
    host                   = aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.cluster.certificate_authority[0].data)
  }
}

# ArgoCD Install
resource "helm_release" "argocd_install" {
  count            = var.ARGOCD_CONFIG.install ? 1 : 0   
  provider         = helm.connect
  name             = "argocd-install"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"

  values           = [ 
    templatefile("${path.module}/utils/argocd-install-values.yaml", {
      argoCdInitPassword = "${var.ARGOCD_CONFIG.init_pass}"
    }) 
  ] 

  depends_on = [
    aws_eks_cluster.cluster, 
    aws_eks_node_group.eks_node_groups#,
    #aws_eks_node_group.spot_managed_node_group   
  ]
}

# Monitoring 
resource "helm_release" "monitor" {
  count            = var.MONITOR_CONFIG.install ? 1 : 0   
  provider         = helm.connect
  name             = "monitor"
  namespace        = "monitor"
  create_namespace = true
  
  repository       = var.MONITOR_CONFIG.repository
  chart            = var.MONITOR_CONFIG.chart
  values           = [ 
    templatefile("${path.module}/utils/${var.MONITOR_CONFIG.values_file}", {
      grafanaInitPassword = "${var.MONITOR_CONFIG.grafanaInitPassword}",
      alertmanagerSlackApiUrl = "${var.MONITOR_CONFIG.alertmanagerSlackApiUrl}",
      alertmanagerSlackChannel = "${var.MONITOR_CONFIG.alertmanagerSlackChannel}"
    }) 
  ]

  depends_on = [
    aws_eks_cluster.cluster, 
    aws_eks_node_group.eks_node_groups#, 
    #aws_eks_node_group.spot_managed_node_group 
  ]
}

# K8s Service Accounts
#resource "kubernetes_service_account" "eks_alb_ingress_svc_account" {
#  metadata {
#    name        = "aws-load-balancer-controller"
#    namespace   = "kube-system"
#    labels      = {
#      "app.kubernetes.io/component" = "controller"
#      "app.kubernetes.io/name" = "aws-load-balancer-controller"
#    }
#    annotations = {
#      "eks.amazonaws.com/role-arn" = aws_iam_role.eks_alb_ingress_role.arn
#    }
#  }
#}

resource "kubernetes_secret" "eks_cluster" {
  count       = var.ARGOCD_CONFIG.install ? 1 : 0
  metadata {
    name      = aws_eks_cluster.cluster.name
    namespace = "argocd"
    labels    = {
      "argocd.argoproj.io/secret-type": "cluster"
    }
  }
  data = {
    name   = aws_eks_cluster.cluster.name
    server = aws_eks_cluster.cluster.endpoint
    config = jsonencode({
      "bearerToken": "${data.aws_eks_cluster_auth.cluster.token}", 
      "tlsClientConfig": {
        "insecure": false,
        "caData": "${aws_eks_cluster.cluster.certificate_authority[0].data}"
      }
    })
  }
  depends_on = [
    helm_release.argocd_install
  ]
}

#resource "kubernetes_secret" "argocd_k8s_repository" {
#  count  = var.ARGOCD_CONFIG.install ? 1 : 0
#  metadata {
#    name      = var.ARGOCD_CONFIG.repository
#    namespace = "argocd"
#    labels    = {
#      "argocd.argoproj.io/secret-type": "repository"
#    }
#  }
#  data = {
#    name = "${var.NAME_PREFIX}-${var.ARGOCD_CONFIG.repository}"
#    url  = var.ARGOCD_CONFIG.repository   
#  }
#
#  depends_on = [
#    helm_release.argocd_install, 
#    kubernetes_secret.eks_cluster
#  ]
#}

# Nginx Ingress Controleer

resource "helm_release" "nginx_ingress_controller" {
  count            = var.NGINX_CONFIG.install ? 1 : 0   
  name             = "nginx-ingress-controller"
  provider         = helm.connect
  namespace        = "nginx"
  create_namespace = true
  repository       = "https://helm.nginx.com/stable"
  chart            = "nginx-ingress"

  values           = [ 
    templatefile("${path.module}/utils/nginx-controller-values.yaml", {
      ingressName      = "${var.NAME_PREFIX}-nginx-ingress-controller",
      serviceName      = var.NGINX_CONFIG.lbName,
      loadBalancerType = var.NGINX_CONFIG.lbType
    }) 
  ]  

  depends_on = [
    aws_eks_cluster.cluster, 
    aws_eks_node_group.eks_node_groups#,
    #aws_eks_node_group.spot_managed_node_group 
  ]
}

resource "kubernetes_namespace" "efs-provisioner" {
  metadata {
    name = "efs-provisioner"
  }

  depends_on = [
      aws_eks_cluster.cluster
  ]
}

# Install AWS Storage CSI for EFS
resource "helm_release" "efs-provisioner" {
  count            = var.EFS_PROVISIONER.install ? 1 : 0   
  provider         = helm.connect
  name             = "efs-provisioner"
  namespace        = "efs-provisioner"
  repository       = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart            = "aws-efs-csi-driver"

  values           = [ 
    templatefile("${path.module}/utils/efs-provisioner-values.yaml", {}) 
  ] 

  depends_on = [
    aws_eks_cluster.cluster, 
    aws_eks_node_group.eks_node_groups,
    kubernetes_namespace.efs-provisioner
  ]
}