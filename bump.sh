#!/bin/bash

set -o errexit
set -o xtrace

osa_url="https://github.com/openstack/openstack-ansible.git"

# Copy gitconfig
cat > ~/.gitconfig << EOF
[gitreview]
        username = evrardjp
[user]
        name = Jean-Philippe Evrard
        email = jean-philippe@evrard.me
EOF

git clone $osa_url "osa-$BRANCH"
echo "Bump SHAs for $BRANCH" > "commitmsg-$BRANCH"
pushd "osa-$BRANCH"
    git checkout "$BRANCH"
    git pull
    git checkout -b bump_osa_requirements
    osa releases bump_upstream_repos_shas
    if [[ "$BRANCH" != "master" ]]; then
        osa releases bump_roles
    fi
    git status
    git diff
    git add .
    git commit -F "../commitmsg-$BRANCH"
    #TODO
    #git review -f -t bump_osa
popd
