data_dir = "/var/data/nomad"
datacenter = "${provider}-${region}"
client {
  enabled = true
  node_class = "demo"
  meta {
    role = "${role}"
  }
}
