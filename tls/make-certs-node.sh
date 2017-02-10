#!/bin/sh -

set -o errexit
set -o nounset
set -o pipefail

cert_group=kube-cert
cert_dir=/etc/kubernetes/ssl
host_cert_dir=/vagrant/artifacts/tls

mkdir -p "$cert_dir"

cp $host_cert_dir/ca.pem $cert_dir/ca.pem
cp $host_cert_dir/ca-key.pem $cert_dir/ca-key.pem

pem_ca=$cert_dir/ca.pem
pem_ca_key=$cert_dir/ca-key.pem

pem_node=$cert_dir/node.pem
pem_node_key=$cert_dir/node-key.pem
pem_node_csr=$cert_dir/node-csr.pem

# Generate TLS artifacts
openssl genrsa -out $pem_node_key 2048
openssl req -new -key $pem_node_key -out $pem_node_csr -subj "/CN=__NODE_IP__" -config /tmp/openssl.cnf
openssl x509 -req -in $pem_node_csr -CA $pem_ca -CAkey $pem_ca_key -CAcreateserial -out $pem_node -days 365 -extensions v3_req -extfile /tmp/openssl.cnf

# Make server certs accessible to apiserver.
chgrp $cert_group $pem_ca $pem_ca_key $pem_node $pem_node_key
chmod 600 $pem_node_key
chmod 660 $pem_node $pem_ca
