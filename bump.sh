#!/bin/bash

set -o errexit
set -o xtrace

osa_url="https://github.com/openstack/openstack-ansible.git"

# Backup gitconfig if it exists already
if [[ -f ~/.gitconfig ]]; then
    cp ~/.gitconfig ~/.gitconfig.old
fi

# Override gitconfig
cat > ~/.gitconfig << EOF
[gitreview]
        username = evrardjp
[user]
        name = Jean-Philippe Evrard
        email = jean-philippe@evrard.me
EOF

branch="$1"
if [[ "$branch" != "master" ]]; then
    gitbranchname="stable/${branch}"
fi

git clone $osa_url "osa-$branch"
echo "Bump SHAs for $gitbranchname" > "commitmsg-$branch"
pushd "osa-$branch"
    git checkout "$gitbranchname"
    git pull
    git checkout -b bump_osa_requirements
    osa releases bump_upstream_shas
    if [[ "$branch" != "master" ]]; then
        osa releases bump_roles
    fi
    git status
    git diff
    git add .
    git commit -F "../commitmsg-$branch"
    osa releases check_pins
    #TODO
    #git review -f -t bump_osa
popd
