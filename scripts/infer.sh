set -x
if [ -z "$SRCDIR" ] ; then
  echo "ERROR: Source code location must be defined in SRCDIR variable"
  exit 1
fi
SRCDIR=`realpath $SRCDIR`
if ! [ -d "$SRCDIR" ] ; then
  echo "ERROR: $SRCDIR does not exist"
  exit 1
fi
WORKSPACE=`pwd`
export INFERCONFIG=$WORKSPACE/inferconfig
INFER_VERSION="1.3.0"
CLANG_VERSION=21 # The version bundled with Infer
SOURCE=`basename $SRCDIR`
BUILDDIR=$WORKSPACE/build-${SOURCE}
INFERDIR=$WORKSPACE/infer-${SOURCE}
rm -rf $BUILDDIR $INFERDIR
mkdir -p $BUILDDIR $INFERDIR
if ! [ -d infer-bin ] ; then
  if ! [ -e "infer-linux-x86_64-v${INFER_VERSION}.tar.xz" ] ; then
    wget -nv https://github.com/facebook/infer/releases/download/v${INFER_VERSION}/infer-linux-x86_64-v${INFER_VERSION}.tar.xz
  fi
  mkdir infer-bin
  tar -xf infer-linux-x86_64-v${INFER_VERSION}.tar.xz -C infer-bin --strip-components=1
fi
if ! [[ "$PATH" =~ infer-bin ]] ; then
  export PATH=$WORKSPACE/infer-bin/bin:$WORKSPACE/infer-bin/lib/infer/facebook-clang-plugins/clang/install/bin/:$PATH
fi
CLANG=$WORKSPACE/infer-bin/lib/infer/facebook-clang-plugins/clang/install/bin/clang-${CLANG_VERSION}
CLANGpp=$WORKSPACE/infer-bin/lib/infer/facebook-clang-plugins/clang/install/bin/clang++
nCPU=$(grep -c processor /proc/cpuinfo)
cd $SRCDIR
git clean -ddffxx
git submodule foreach --recursive git clean -ddffxx
cd $WORKSPACE
. $SRCDIR/VERSION
ver="$MYSQL_VERSION_MAJOR.$MYSQL_VERSION_MINOR"
if [ $ver == "10.6" ] ; then
  targets="GenError GenServerSource GenFixPrivs"
else
  targets="GenError GenServerSource GenUnicodeDataSource GenFixPrivs"
fi
if [ -e $SRCDIR/cmake/build_configurations/enterprise.cmake ] ; then
  build_config=enterprise
else
  build_config=mysql_release
fi
cmake -DBUILD_CONFIG=${build_config} -DPLUGIN_COLUMNSTORE=NO \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DCMAKE_C_COMPILER=$CLANG -DCMAKE_CXX_COMPILER=$CLANGpp \
  -S $SRCDIR -B $BUILDDIR
cmake --build $BUILDDIR --target $targets --parallel $nCPU
cd $BUILDDIR
infer capture --compilation-database compile_commands.json \
  --project-root $SRCDIR --results-dir $INFERDIR
infer analyze \
  --project-root $SRCDIR --results-dir $INFERDIR
if [ -e $INFERDIR/report.txt ] ; then
  cp $INFERDIR/report.txt $WORKSPACE/result-${SOURCE}.txt
fi


