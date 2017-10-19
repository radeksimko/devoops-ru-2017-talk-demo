data_dir = "/var/data/consul"
datacenter = "${provider}-${region}"
ui = ${enable_ui}
bind_addr = "{{ GetInterfaceIP \"${iface_name}\" }}"
client_addr = "${client_address}"
node_meta {
  role = "${role}"
}
retry_join = [
  "provider=${provider} tag_key=Name tag_value=${tag_value}"
]
