#!/bin/bash
set -e
export TMPDIR=/tmp/docker-build-$RANDOM
exit_trap() {
    cd /
    rm -rf "$TMPDIR"
}
trap exit_trap EXIT
mkdir "$TMPDIR"
cd "$TMPDIR"
cat >> build <<EOF
user={{ pillar.jupyterhub.admin_user }}
id={{ pillar.jupyterhub.admin_id }}
groupadd -g "$id" "$user"
useradd -m -s /bin/bash -g "$user" -u "$id" "$user"
echo "$user:{{ pillar.jupyterhub.admin_passwd }}" | chpasswd
pip install 'ipython[notebook]'
rm -rf ~/.cache
cd /
rm -rf /build
EOF
cat >> Dockerfile <<'EOF'
FROM jupyter/jupyterhub
ADD . /build
RUN /build/build
EOF
docker build -t jupyterhub .
