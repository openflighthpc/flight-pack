#!/bin/bash
cd /opt/flight/opt/pack
/opt/flight/bin/bundle install --path=vendor
cp dist/opt/flight/libexec/commands/pack /opt/flight/libexec/commands/pack
cat <<EOF > /opt/flight/opt/pack/etc/config.yml
---
pack_paths:
  - /opt/flight/var/lib/pack/packs
repo_paths:
  - /opt/flight/var/lib/pack/repos
log_path: /opt/flight/var/log
store_dir: /opt/flight/var/cache/pack
EOF
mkdir -p /opt/flight/var/log
mkdir -p /opt/flight/var/cache/pack
mkdir -p /opt/flight/var/lib/pack
/opt/flight/bin/flight pack repoadd https://alces-flight-packs.s3.eu-west-2.amazonaws.com/v1/core.yml
