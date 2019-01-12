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
if [[ "$branch" == "master" ]]; then
    gitbranchname="master"
else
    gitbranchname="stable/${branch}"
fi

git clone $osa_url "osa-$branch"
echo "Bump SHAs for $gitbranchname" > "commitmsg-$branch"
pushd "osa-$branch"
    git checkout "$gitbranchname"
    git pull
    git checkout -b bump_osa_requirements
    osa releases bump_upstream_shas
    #TODO(evrardjp): Remove this conditional and update the fonction
    #update_ansible_role_requirements_file to track, for external roles,
    #not only master.
    if [[ "$branch" != "master" ]]; then
        osa releases bump_roles "$gitbranchname"
    fi
    git status
    git diff
    git add .
    git commit -F "../commitmsg-$branch"
    osa releases check_pins
    if [[ $(expr `date +'%V'` % 2) -eq 0 ]]; then
        echo "Even week number, bumping!"
        git review -f -t bump_osa
    else
        echo "Odd week number, I am only displaying this for a status update"
    fi
popd
