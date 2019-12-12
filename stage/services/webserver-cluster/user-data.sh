#!/bin/bash

# Terraform variables can be referenced here.
# Terraform will render them before executing the script

cat > index.html <<EOF
<h1>hello there from AWS Cluster 😎</h1>
<p><strong>DB address: </strong>${db_address}</p>
<p><strong>DB port: </strong>${db_port}</p>
EOF

nohup busybox httpd -f -p ${server_port} &