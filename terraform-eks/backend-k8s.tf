resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name = "backend"
    labels = {
      app = "backend"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "backend"
      }
    }

    template {
      metadata {
        labels = {
          app = "backend"
        }
      }

      spec {
        container {
          name  = "backend"
          image = "725537514866.dkr.ecr.us-east-1.amazonaws.com/backend-api:latest"

          port {
            container_port = 8000
          }

          env {
            name  = "DB_NAME"
            value = "testdb"
          }

          env {
            name  = "DB_USER"
            value = "postgres"
          }

          env {
            name  = "DB_PASSWORD"
            value = "postgres"
          }

          env {
            name  = "DB_HOST"
            value = "postgres"
          }

          env {
            name  = "DB_PORT"
            value = "5432"
          }

          readiness_probe {
            http_get {
              path = "/ready"
              port = 8000
            }

            initial_delay_seconds = 5
            period_seconds        = 5
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8000
            }

            initial_delay_seconds = 10
            period_seconds        = 10
          }
        }
      }
    }
  }
}
