resource "kubernetes_pod_v1" "postgres" {
  metadata {
    name = "postgres"
    labels = {
      app = "postgres"
    }
  }

  spec {
    container {
      name  = "postgres"
      image = "725537514866.dkr.ecr.us-east-1.amazonaws.com/postgres:15"

      env {
        name  = "POSTGRES_DB"
        value = "testdb"
      }

      env {
        name  = "POSTGRES_USER"
        value = "postgres"
      }

      env {
        name  = "POSTGRES_PASSWORD"
        value = "postgres"
      }

      port {
        container_port = 5432
      }
    }
  }
}
