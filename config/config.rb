$new_discovery_url="https://discovery.etcd.io/new?size=#{$num_instances}"
$image_version = "current"
$update_channel='stable'
$kubernetes_masters = 1
$kubernetes_workers = 2

# Customize VMs
$vm_private_key = File.join(File.dirname(__FILE__), "../keys/id_rsa")
$vm_public_key = File.join(File.dirname(__FILE__), "../keys/id_rsa.pub")
$vm_gui = false
$vm_memory = 1024
$vm_cpus = 1
$vb_cpuexecutioncap = 100

$mac_addresses = {
  :master_1 => '0800278DC14D',
  :node_1   => '0800278DC15D',
  :node_2   => '0800278DC16D',
  :node_3   => '0800278DC17D',
}

if File.exists?('config/user-data.in') && ARGV[0].eql?('up')
  require 'open-uri'
  require 'yaml'

  token = open($new_discovery_url).read

  data = YAML.load(IO.readlines('config/user-data.in')[1..-1].join)
  pub_key = IO.readlines($vm_public_key)

  if data.key? 'coreos' and data['coreos'].key? 'etcd'
    data['coreos']['etcd']['discovery'] = token
  end

  if data.key? 'coreos' and data['coreos'].key? 'etcd2'
    data['coreos']['etcd2']['discovery'] = token
  end

  if data.key? 'ssh_authorized_keys'
    data['ssh_authorized_keys'] = pub_key
  end

  # Fix for YAML.load() converting reboot-strategy from 'off' to `false`
  if data.key? 'coreos' and data['coreos'].key? 'update' and data['coreos']['update'].key? 'reboot-strategy'
    if data['coreos']['update']['reboot-strategy'] == false
      data['coreos']['update']['reboot-strategy'] = 'off'
    end
  end

  yaml = YAML.dump(data)
  File.open('config/user-data', 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
end
