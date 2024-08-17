##############
## MINIKUBE ##
##############

module "minikube_cluster" {
  #count              = var.instance.install ? 1 : 0
  source             = "github.com/kramfs/tf-minikube-cluster"
  cluster_name       = lookup(var.minikube, "cluster_name", "minikube")
  driver             = lookup(var.minikube, "driver", "docker")                # # Options: docker, podman, kvm2, qemu, hyperkit, hyperv, ssh
  kubernetes_version = lookup(var.minikube, "kubernetes_version", null)        # See options: "minikube config defaults kubernetes-version" or refer to: https://kubernetes.io/releases/
  container_runtime  = lookup(var.minikube, "container_runtime", "containerd") # Default: containerd. Options: docker, containerd, cri-o
  nodes              = lookup(var.minikube, "nodes", "1")
}

################
## KUBERNETES ##
################

provider "kubernetes" {
  #config_path = "~/.kube/config"
  host = module.minikube_cluster.minikube_cluster_host

  client_certificate     = module.minikube_cluster.minikube_cluster_client_certificate
  client_key             = module.minikube_cluster.minikube_cluster_client_key
  cluster_ca_certificate = module.minikube_cluster.minikube_cluster_ca_certificate
}

/*
resource "time_sleep" "wait_15_seconds" {
  depends_on = [minikube_cluster.docker]
  create_duration = "15s"
}
*/

##################
## HELM SECTION ##
##################

## HELM PROVIDER ##
provider "helm" {
  kubernetes {
    host                   = module.minikube_cluster.minikube_cluster_host
    client_certificate     = module.minikube_cluster.minikube_cluster_client_certificate
    client_key             = module.minikube_cluster.minikube_cluster_client_key
    cluster_ca_certificate = module.minikube_cluster.minikube_cluster_ca_certificate
  }
}


## HELM RELEASE ##

# METALLB
# REF: https://artifacthub.io/packages/helm/metallb/metallb
resource "helm_release" "metallb" {
  count            = var.metallb.install ? 1 : 0
  name             = var.metallb.name
  namespace        = var.metallb.namespace
  create_namespace = var.metallb.create_namespace

  repository = var.metallb.repository
  chart      = var.metallb.chart
  version    = lookup(var.metallb, "version", null) # Chart version

  #values = [
  #  templatefile("./helm_values/metallb-system.yaml", {
  #    serviceMonitor_enabled = lookup(var.metallb, "serviceMonitor_enabled", false) # Check if servicemonitor will be enabled
  #  })
  #]

  provisioner "local-exec" {
    command = "kubectl apply -f ./helm_values/metallb-system-config.yaml"
  }
}

# ARGOCD
# REF: https://artifacthub.io/packages/helm/argo/argo-cd
resource "helm_release" "argocd" {
  name             = var.argocd.name
  namespace        = var.argocd.namespace
  create_namespace = var.argocd.create_namespace

  repository = var.argocd.repository
  chart      = var.argocd.chart
  version    = lookup(var.argocd, "version", null) # Chart version

  #values = [
  #  file("./values.yaml")
  #]

  values = [templatefile("./helm_values/argocd.yaml", {
    server_service_type    = var.argocd.server_service_type
    timeout_reconciliation = var.argocd.timeout_reconciliation # Reconciliation timeout (drift) how often it will sync ArgoCD with the Git repository.
  })]
}

# ARGO ROLLOUTS
# REF: https://artifacthub.io/packages/helm/argo/argo-rollouts
resource "helm_release" "argo-rollouts" {
  name             = var.argo-rollouts.name
  namespace        = var.argo-rollouts.namespace
  create_namespace = var.argo-rollouts.create_namespace

  repository = var.argo-rollouts.repository
  chart      = var.argo-rollouts.chart
  version    = lookup(var.argo-rollouts, "version", null) # Chart version

  #values = [
  #  file("./values.yaml")
  #]

  #values = [templatefile("./helm_values/argo-rollouts.yaml", {
  #  server_service_type    = var.argo-rollouts.server_service_type
  #  timeout_reconciliation = var.argo-rollouts.timeout_reconciliation
  #})]
}