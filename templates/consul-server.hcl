server = true
bootstrap_expect = ${desired_capacity}
data_dir = "/var/data/consul"
datacenter = "${provider}-${region}"
retry_join = [
  "provider=${provider} tag_key=Name tag_value=${tag_value}"
]
