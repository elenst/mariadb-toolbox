#!/bin/bash

echo
date
echo

parse_arg()
{
  echo "$1" | sed -e 's/^[^=]*=//' | sed -e 's/,/ /g'
}

usage()
{
    cat <<EOF
Usage:
    $0
       --bldhome=<common location for per-branch builds>
       --srchome=<common location of per-branch sources>
       --remote-repo=<location of the repo to clone/pull from>
       --branches=<comma-separated list of branches to build>
       --build-types=<comma-separated list of builds to build. Available variants: rel, deb, asan>
       --help (print this help and exit)
EOF
}

for arg in $* ; do
    case "$arg" in
        --bin-home=*|--binhome=*|--bldhome=*|--bld-home=*) bldhome=`parse_arg "$arg"` ;;
        --source-home=*|--sourcehome=*|--src-home=*|--srchome=*) srchome=`parse_arg "$arg"` ;;
        --remote-source=*|--remote-repo=*) remote_repo=`parse_arg "$arg"` ;;
        --branches=*) branches=`parse_arg "$arg"` ;;
        --build-types=*|--builds=*) build_types=`parse_arg "$arg"` ;;
        --help) usage && exit 0 ;;
        *) echo "Unknown argument: $arg" && exit 1 ;;
    esac
done

if [ -z "$bldhome" ] ; then
    usage
    echo "ERROR: bldhome not defined"
    exit 1
fi
if [ -z "$srchome" ] ; then
    usage
    echo "ERROR: srchome not defined"
    exit 1
fi
if [ -z "$remote_repo" ] ; then
    usage
    echo "ERROR: remote-repo not defined"
    exit 1
fi
if [ -z "$branches" ] ; then
    usage
    echo "ERROR: No branches defined"
    exit 1
fi
if [ -z "$build_types" ] ; then
    usage
    echo "ERROR: No build types defined"
    exit 1
fi

for b in $branches ; do
    srcdir=$srchome/$b
    `dirname $0`/update_git_trees.sh $remote_repo/$b $srchome $b
    cd $srcdir
    revno=`git log -1 --abbrev=8 --pretty="%h"`
    for t in $build_types ; do
        bindir=$bldhome/$b-$revno-$t
        symlink=$bldhome/$b-$t
        if [ -e $bindir ] ; then
            echo "$t build for branch $b revision $revno already exists"
        else
            echo "Building $t build for branch $b revision $revno"
            case $t in
                rel)  cmake_options="-DBUILD_CONFIG=enterprise" ;;
                deb)  cmake_options="-DCMAKE_BUILD_TYPE=Debug" ;;
                asan) cmake_opitons="-DCMAKE_BUILD_TYPE=Debug -DWITH_ASAN=YES -DMYSQL_MAINTAINER_MODE=OFF" ;;
                *) echo "ERROR: Unknown build type: $t" && exit 1 ;;
            esac
            rm -rf /dev/shm/tmp_build
            mkdir /dev/shm/tmp_build
            cd /dev/shm/tmp_build
            if cmake $srcdir $cmake_args -DCMAKE_INSTALL_PREFIX=$bindir ; then
                if make -j16 ; then
                    rm -rf $bindir
                    if make install ; then
                        rm -f $symlink
                        ln -s $bindir $symlink
                    else
                        echo "ERROR: install failed, see the output above"
                    fi
                else
                    echo "ERROR: Build failed, see the output above"
                fi
            else
                echo "ERROR: Cmake failed, see the output above"
            fi
        fi
        echo
    done
done
