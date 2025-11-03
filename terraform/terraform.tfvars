# Enable a single always-on SPOT node so workloads have compute capacity.
enable_spot_node_group = true
node_min_size          = 1
node_desired_size      = 1
node_max_size          = 1

# Uncomment and set to an existing EC2 key pair name to allow SSH access.
# ssh_key_name = "my-ec2-keypair"

