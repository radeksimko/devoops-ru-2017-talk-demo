job "nomad-echo" {
  datacenters = ["gce-europe-west2", "aws-eu-west-2"]
  type = "service"

  group "default" {
    count = 6

    task "nomad-echo" {
      driver = "exec"

      config {
        command = "nomad-http-echo"
        args = ["-text=\"hello from nomad\"", "-listen=:22222"]
      }

      artifact {
        source = "https://s3.eu-west-2.amazonaws.com/radek-consul-download/nomad-http-echo"
        destination = "local/nomad-http-echo"
        mode = "file"
        options {
          checksum = "sha256:a83064caefc5d9b26b73c1bc5b4e51ec3c20b1818ddca8cd477f26a48bd2a50e"
        }
      }

      service {
        name = "nomad-echo"
        port = "http"

        tags = ["urlprefix-/nomad-echo"]

        check {
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "5s"
          timeout  = "2s"
        }
      }

      resources {
        cpu = 256
        memory = 128
        network {
          port "http" {
            static = 22222
          }
        }
      }
    }
  }
}
