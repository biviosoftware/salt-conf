#!/bin/bash
set -e
channel_tag=$1
base=jupyterhub
tag=$base:$(date -u +%Y%m%d.%H%M%S)
(
    set -e
    export TMPDIR=/tmp/docker-build-$RANDOM
    exit_trap() {
        cd /
        rm -rf "$TMPDIR"
    }
    trap exit_trap EXIT
    mkdir "$TMPDIR"
    cd "$TMPDIR"
    # Need to have this, due to ONBUILD image
    # https://github.com/jupyterhub/jupyterhub/issues/491
    touch jupyterhub_config.py
    cat >> build <<'EOF'
set -e
user={{ pillar.jupyterhub.admin_user }}
id={{ pillar.jupyterhub.admin_id }}
groupadd -g "$id" "$user"
useradd -m -s /bin/bash -g "$user" -u "$id" "$user"
echo "$user:{{ pillar.jupyterhub.admin_passwd }}" | chpasswd -e
pip install 'ipython[notebook]'
pip install git+git://github.com/jupyter/oauthenticator.git
rm -rf ~/.cache
cd /
rm -rf /build
EOF
    cat >> Dockerfile <<'EOF'
FROM jupyter/jupyterhub
COPY . /build
RUN ["bash", "/build/build"]
EOF
    docker build -t $base .
    docker tag $base:latest "$tag"
    docker tag -f $base:latest "$channel_tag"
) 1>&2
if (( $? )); then
    exit 1
fi
echo "changed=yes comment='Build: $tag; $channel_tag'"
