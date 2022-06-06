variable "ingressClassName" {
  type    = string
  default = "nginx"
}

variable "host" { default = [
  "argocd.bulat.com"
] }


variable "argo-args" {

  default = [
    "--insecure"
  ]

}


variable "annotations" {

  default = {
    "kubernetes.io / ingress.class"                    = "nginx",
    "nginx.ingress.kubernetes.io / force-ssl-redirect" = true,
    "nginx.ingress.kubernetes.io / ssl-passthrough"    = true
  }

}
