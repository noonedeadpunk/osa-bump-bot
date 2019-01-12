#!/bin/bash

set -o errexit
set -o xtrace

osa_url="https://github.com/openstack/openstack-ansible.git"

# Add openstack's gerrit ssh public key
# Known public key
gerrit_pubkey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfsIj/jqpI+2CFdjCL6kOiqdORWvxQ2sQbCzSzzmLXic8yVhCCbwarkvEpfUOHG4eyB0vqVZfMffxf0Yy3qjURrsroBCiuJ8GdiAcGdfYwHNfBI0cR6kydBZL537YDasIk0Z3ILzhwf7474LmkVzS7V2tMTb4ZiBS/jUeiHsVp88FZhIBkyhlb/awAGcUxT5U4QBXCAmerYXeB47FPuz9JFOVyF08LzH9JRe9tfXtqaCNhlSdRe/2pPRvn2EIhn5uHWwATACG9MBdrK8xv8LqPOik2w1JkgLWyBj11vDd5I3IjrmREGw8dqImqp0r6MD8rxqADlc1elfDIXYsy+TVH"
# Found public key (for comparison purposes, avoiding mitm)
gerrit_found_pubkey=$(ssh-keyscan -p 29418 review.openstack.org 2>/dev/null | cut -d ' ' -f '2,3')

if [[ ${gerrit_pubkey} != ${gerrit_found_pubkey} ]]; then
    echo "Alert! MITM detected"
    exit 1
else
    echo "Good key found, can ssh in"
    echo ${gerrit_pubkey} >> ~/.ssh/known_hosts
fi

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
    if [[ $(( $(date +'%V') % 2)) -eq 0 ]]; then
        echo "Even week number, bumping!"
        git review -f -t bump_osa
    else
        echo "Odd week number, I am only displaying this for a status update"
    fi
popd
