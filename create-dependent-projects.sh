#!/bin/sh
set -euo pipefail

# Usage:
# ./create-dependent-projects.sh <dir> <package>
# For each dependency <dep> of <package>, create a directory <dir>/<dep> containing a
# dune project depending on <dep>.

DUNE_VERSION=3.14

make_dune_project_in_dir_with_dep() {
    local dir=$1
    local name=$2
    local dep=$3
    if [ -z ${4+x} ]; then
        local depends=$dep
    else
        local depends="($dep (= $4))"
    fi

    echo "Making project in $dir which will depend on $dep..." > /dev/stderr
    mkdir -p $dir
    pushd $dir > /dev/null
    cat > dune-workspace <<EOF
(lang dune $DUNE_VERSION)
(lock_dir
 (constraints ocaml-system))
EOF
    cat > dune-project <<EOF
(lang dune $DUNE_VERSION)
(package
 (name $name)
 (allow_empty)
 (depends $depends))
EOF
    popd > /dev/null
}

transitive_closure_of_package() {
    local package=$1

    local temp=$(mktemp -d)
    trap "rm -rf -- '$temp'" EXIT
    make_dune_project_in_dir_with_dep $temp depends-on-$package $package
    pushd $temp > /dev/null
    dune pkg lock > /dev/null 2> /dev/null
    ls -1 dune.lock/*.pkg | while read file; do
        local name=$(echo $file | sed 's#dune.lock/\(.*\)\.pkg#\1#')
        local version=$(cat $file | grep '(version .*)' | sed 's/(version \(.*\))/\1/')
        echo $name $version
    done
    popd > /dev/null
}

main() {
    local dir=$1
    local root_package=$2

    transitive_closure_of_package $root_package | while read package version; do
        make_dune_project_in_dir_with_dep $dir/$package depends-on-$package $package $version
    done
}

main $@
