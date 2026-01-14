resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name = "frontend"
    labels = {
      app = "frontend"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "frontend"
        }
      }

      spec {
        container {
          name  = "frontend"
          image = "725537514866.dkr.ecr.us-east-1.amazonaws.com/frontend-app"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}
