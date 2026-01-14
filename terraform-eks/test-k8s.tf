resource "kubernetes_namespace_v1" "test" {
    metadata {
        name = "terraform-test"
    }
}