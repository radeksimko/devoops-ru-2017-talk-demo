job "fabio" {
  datacenters = ["gce-europe-west2", "aws-eu-west-2"]
  type = "system"

  group "fabio" {
    task "fabio" {
      driver = "exec"

      config {
        command = "fabio"
      }

      artifact {
        source = "https://github.com/fabiolb/fabio/releases/download/v1.5.2/fabio-1.5.2-go1.9.1-linux_amd64"
        destination = "local/fabio"
        mode = "file"
        options {
          checksum = "sha256:7e7eee2dbe73354c16f5500eee9e53f3c51ec0def68ddd89f2ba3ad9f633255f"
        }
      }

      resources {
        cpu = 512
        memory = 512
      }
    }
  }
}
