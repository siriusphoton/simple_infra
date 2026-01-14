resource "kubernetes_service_v1" "backend" {
  metadata {
    name = "backend"
  }

  spec {
    selector = {
      app = "backend"
    }

    port {
      port        = 8000
      target_port = 8000
    }
  }
}
