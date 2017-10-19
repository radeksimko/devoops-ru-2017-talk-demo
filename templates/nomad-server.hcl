data_dir = "/var/data/nomad"
datacenter = "${provider}-${region}"
server {
  enabled          = true
  bootstrap_expect = ${desired_capacity}
}
