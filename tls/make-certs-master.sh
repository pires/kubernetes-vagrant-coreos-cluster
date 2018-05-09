#!/bin/sh -

set -o errexit
set -o nounset
set -o pipefail

cert_group=kube-cert
cert_dir=/etc/kubernetes/ssl

pem_ca=$cert_dir/ca.pem
pem_ca_key=$cert_dir/ca-key.pem
pem_server=$cert_dir/apiserver.pem
pem_server_key=$cert_dir/apiserver-key.pem
pem_server_csr=$cert_dir/apiserver-csr.pem

pem_admin=/vagrant/artifacts/tls/admin.pem
pem_admin_key=/vagrant/artifacts/tls/admin-key.pem
pem_admin_csr=/vagrant/artifacts/tls/admin-csr.pem

# Generate TLS artifacts
mkdir -p "$cert_dir"

openssl genrsa -out $pem_ca_key 2048 
openssl req -x509 -new -nodes -key $pem_ca_key -days 10000 -out $pem_ca -subj "/CN=kube-ca"

openssl genrsa -out $pem_server_key 2048
openssl req -new -key $pem_server_key -out $pem_server_csr -subj "/CN=kube-apiserver" -config /tmp/openssl.cnf
openssl x509 -req -in $pem_server_csr -CA $pem_ca -CAkey $pem_ca_key -CAcreateserial -out $pem_server -days 365 -extensions v3_req -extfile /tmp/openssl.cnf

# Make server certs accessible to apiserver.
chgrp $cert_group $pem_ca $pem_ca_key $pem_server $pem_server_key
chmod 600 $pem_ca_key $pem_server_key
chmod 660 $pem_ca $pem_server

# Copy CA stuff to host so worked nodes can use it
cp $pem_ca $pem_ca_key /vagrant/artifacts/tls

# Generate admin
openssl genrsa -out $pem_admin_key 2048
openssl req -new -key $pem_admin_key -out $pem_admin_csr -subj "/CN=kube-admin/O=system:masters"
openssl x509 -req -in $pem_admin_csr -CA $pem_ca -CAkey $pem_ca_key -CAcreateserial -out $pem_admin -days 365
