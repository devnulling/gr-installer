#!/bin/bash

# Instructions
# make sure /home/$user/sdr/installs is a valid folder
# copy this file to /home/$user/sdr/sdr.sh
# chmod +x /home/$user/sdr/sdr.sh
# cd /home/$user/sdr
# ./sdr.sh -u $UHD_VERSION -g $GR_VERSION
# ./sdr.sh -u v3.14.1.1 -g maint-3.7
# currently only works with GR 3.7.x.x (python path needs to be updated for 3.8.x.x)

set -e

SDR_BASE_DIR="/home/$USER/sdr"
SDR_INSTALL_TARGET="$SDR_BASE_DIR/installs"

if [ ! -d "$SDR_BASE_DIR" ]; then
    echo "$SDR_BASE_DIR does not exist, creating the folder"
    mkdir -p $SDR_BASE_DIR
fi

if [ ! -d "$SDR_INSTALL_TARGET" ]; then
    echo "$SDR_INSTALL_TARGET does not exist, creating the folder"
    mkdir -p $SDR_INSTALL_TARGET
fi

RFNOC_INSTALL=NO
E300_INSTALL=NO
UHD_VERSION="master"
GR_VERSION="master"
BUILD_CORES=7
GR_FULL_INSTALL=NO
INSTALL_DEPS=NO

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	# UHD Version
    -u|--uhd)
    UHD_VERSION="$2"
    shift
    shift
    ;;
    # GNU Radio version
    -g|--gnuradio)
    GR_VERSION="$2"
    shift
    shift
    ;;
    # If it is a RFNoC install
    --rfnoc)
    RFNOC_INSTALL=YES
    shift 
    ;;
    # If it is a E300 install
    --e300)
    E300_INSTALL=YES
    shift 
    ;;
    # Number of cores to use
    -c|--cores)
    BUILD_CORES="$2"
    shift
    shift
    ;;
    # Enable a full GR install
    --gr_full)
    GR_FULL_INSTALL=YES
    shift 
    ;;
    # Install ubuntu deps and exit
    --deps)
    INSTALL_DEPS=YES
    shift 
    ;;
   
esac
done


if [ "$INSTALL_DEPS" == "YES" ]; then
	# install deps
	sudo apt-get -y install git swig cmake doxygen build-essential libboost-all-dev libtool libusb-1.0-0 libusb-1.0-0-dev libudev-dev libncurses5-dev libfftw3-bin libfftw3-dev libfftw3-doc libcppunit-1.14-0 libcppunit-dev libcppunit-doc ncurses-bin cpufrequtils python-numpy python-numpy-doc python-numpy-dbg python-scipy python-docutils qt4-bin-dbg qt4-default qt4-doc libqt4-dev libqt4-dev-bin python-qt4 python-qt4-dbg python-qt4-dev python-qt4-doc python-qt4-doc libqwt6abi1 libfftw3-bin libfftw3-dev libfftw3-doc ncurses-bin libncurses5 libncurses5-dev libncurses5-dbg libfontconfig1-dev libxrender-dev libpulse-dev swig g++ automake autoconf libtool python-dev libfftw3-dev libcppunit-dev libboost-all-dev libusb-dev libusb-1.0-0-dev fort77 libsdl1.2-dev python-wxgtk3.0 git libqt4-dev python-numpy ccache python-opengl libgsl-dev python-cheetah python-mako python-lxml doxygen qt4-default qt4-dev-tools libusb-1.0-0-dev libqwtplot3d-qt5-dev pyqt4-dev-tools python-qwt5-qt4 cmake git wget libxi-dev gtk2-engines-pixbuf r-base-dev python-tk liborc-0.4-0 liborc-0.4-dev libasound2-dev python-gtk2 libzmq3-dev libzmq5 python-requests python-sphinx libcomedi-dev python-zmq libqwt-dev libqwt6abi1 python-six libgps-dev libgps23 gpsd gpsd-clients python-gps python-setuptools
	echo "Deps installed, re-run with UHD/GR versions"
	exit 0	
fi

SDR_UHD_VERSION=$UHD_VERSION
SDR_GR_VERSION=$GR_VERSION

if [ "$RFNOC_INSTALL" == "YES" ]; then
	SDR_INSTALL_UID="rfnoc_${SDR_UHD_VERSION}_${SDR_GR_VERSION}"
else
	SDR_INSTALL_UID="${SDR_UHD_VERSION}_${SDR_GR_VERSION}"
fi

SDR_INSTALL_BASE="$SDR_INSTALL_TARGET/$SDR_INSTALL_UID"
SDR_SRC_TARGET="$SDR_INSTALL_BASE/src"
SDR_UHD_SRC_BASE="$SDR_SRC_TARGET/uhd"
SDR_GR_SRC_BASE="$SDR_SRC_TARGET/gnuradio"
SDR_ENV_FILE="$SDR_INSTALL_BASE/setup.env"
SDR_OOT_DIR="$SDR_INSTALL_BASE/oots"
SDR_OOT_BUILDER_FILE="$SDR_INSTALL_BASE/oot.sh"

if [ "$GR_FULL_INSTALL" == "YES" ]; then
	SDR_GR_CMAKE="cmake -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE -DUHD_DIR=$SDR_INSTALL_BASE/lib/cmake/uhd/ -DUHD_INCLUDE_DIRS=$SDR_INSTALL_BASE/include/ -DUHD_LIBRARIES=$SDR_INSTALL_BASE/lib/libuhd.so ../"
else
	SDR_GR_CMAKE="cmake -DENABLE_GR_DTV=OFF -DENABLE_GR_ATSC=OFF -DENABLE_GR_PAGER=OFF -DENABLE_GR_FCD=OFF -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE -DUHD_DIR=$SDR_INSTALL_BASE/lib/cmake/uhd/ -DUHD_INCLUDE_DIRS=$SDR_INSTALL_BASE/include/ -DUHD_LIBRARIES=$SDR_INSTALL_BASE/lib/libuhd.so ../"
fi

if [ "$RFNOC_INSTALL" == "YES" ]; then
	
	if [ "$E300_INSTALL" == "YES" ]; then
		SDR_UHD_CMAKE="cmake -DENABLE_RFNOC=ON -DENABLE_E300=ON -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE ../"
	else
		SDR_UHD_CMAKE="cmake -DENABLE_RFNOC=ON -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE ../"
	fi
else
	
	if [ "$E300_INSTALL" == "YES" ]; then
		SDR_UHD_CMAKE="cmake -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE -DENABLE_E300=ON ../"
	else
		SDR_UHD_CMAKE="cmake -DCMAKE_INSTALL_PREFIX=$SDR_INSTALL_BASE ../"
	fi
   
fi

echo "INSTALLING VERSIONS/OPTIONS"
echo "------------------------------"
echo "UHD VERSION          = ${UHD_VERSION}"
echo "GR VERSION           = ${GR_VERSION}"
echo "RFNoC                = ${RFNOC_INSTALL}"
echo "E300                 = ${E300_INSTALL}"
echo "CORES                = ${BUILD_CORES}"
echo "GR FULL              = ${GR_FULL_INSTALL}"
echo "SDR_INSTALL_BASE     = ${SDR_INSTALL_BASE}"
echo "SDR_SRC_TARGET       = ${SDR_SRC_TARGET}"
echo "SDR_ENV_FILE         = ${SDR_ENV_FILE}"
echo "SDR_OOT_DIR          = ${SDR_OOT_DIR}"
echo "SDR_OOT_BUILDER_FILE = ${SDR_OOT_BUILDER_FILE}"
echo "------------------------------"

check_dir(){
	CURRENT_DIR=`pwd`
	echo "[ INFO ] Current Directory: $CURRENT_DIR"
}

create_dirs(){
	mkdir -p $SDR_BASE_DIR
	mkdir -p $SDR_SRC_TARGET
	mkdir -p $SDR_INSTALL_TARGET
	mkdir -p $SDR_INSTALL_BASE
	mkdir -p $SDR_UHD_SRC_BASE
	mkdir -p $SDR_OOT_DIR
}

install_uhd(){
	cd $SDR_SRC_TARGET
	check_dir

	git clone --recursive https://github.com/ettusresearch/uhd $SDR_UHD_SRC_BASE

	cd "$SDR_UHD_SRC_BASE/"
	check_dir

	git checkout $SDR_UHD_VERSION
	git submodule update --init --recursive

	cd "$SDR_UHD_SRC_BASE/host"
	check_dir

	mkdir -p "$SDR_UHD_SRC_BASE/host/build"
	cd "$SDR_UHD_SRC_BASE/host/build"
	check_dir

	echo $SDR_UHD_CMAKE

	eval $SDR_UHD_CMAKE
	make -j${BUILD_CORES}
	make install
	source $SDR_ENV_FILE
	uhd_usrp_probe --version
	uhd_images_downloader
}

install_gr(){
	cd $SDR_SRC_TARGET
	check_dir
	git clone -b $SDR_GR_VERSION --recursive https://github.com/gnuradio/gnuradio $SDR_GR_SRC_BASE
	cd $SDR_GR_SRC_BASE
	check_dir
	git checkout $SDR_GR_VERSION
	git submodule update --init --recursive
	mkdir -p "${SDR_GR_SRC_BASE}/build"
	cd "${SDR_GR_SRC_BASE}/build"
	check_dir
	
	echo $SDR_GR_CMAKE
	eval $SDR_GR_CMAKE
	make -j${BUILD_CORES}
	make install
	gnuradio-config-info --version
}

write_env_file(){
	SDR_BASE_PATH="$SDR_INSTALL_BASE"
	SDR_PATH="$SDR_BASE_PATH/bin:$PATH"
	SDR_LD_LIBRARY_PATH="$SDR_BASE_PATH/lib:$LD_LIBRARY_PATH"
	SDR_PYTHONPATH_1="$SDR_BASE_PATH/lib/python2.7/site-packages"
	SDR_PYTHONPATH_2="$SDR_BASE_PATH/lib/python2.7/dist-packages"
	SDR_PKG_CONFIG="$SDR_BASE_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"


	echo "Writing Environment File: $SDR_ENV_FILE"
	echo "export BASE_PATH=$SDR_BASE_PATH" > $SDR_ENV_FILE
	echo "export PATH=$SDR_PATH" >> $SDR_ENV_FILE
	echo "export LD_LIBRARY_PATH=$SDR_LD_LIBRARY_PATH" >> $SDR_ENV_FILE
	echo "export PYTHONPATH=$SDR_PYTHONPATH_1:$SDR_PYTHONPATH_2" >> $SDR_ENV_FILE
	echo "export PKG_CONFIG_PATH=$SDR_PKG_CONFIG" >> $SDR_ENV_FILE
}

write_oot_builder(){

	echo "Writing OOT Builder"

	echo "#!/bin/bash" > $SDR_OOT_BUILDER_FILE
	echo "SDR_INSTALL_BASE=\"$SDR_INSTALL_BASE\"" >> $SDR_OOT_BUILDER_FILE
	echo "SDR_CMAKE_COMMAND=\"cmake -DCMAKE_INSTALL_PREFIX=\$SDR_INSTALL_BASE -DUHD_DIR=\$SDR_INSTALL_BASE/lib/cmake/uhd/ -DUHD_INCLUDE_DIRS=\$SDR_INSTALL_BASE/include/ -DUHD_LIBRARIES=\$SDR_INSTALL_BASE/lib/libuhd.so -DGNURADIO_ALL_INCLUDE_DIRS=\$SDR_INSTALL_BASE/include/ -DGNURADIO_RUNTIME_LIBRARY_DIRS=\$SDR_INSTALL_BASE/lib/ ../\"" >> $SDR_OOT_BUILDER_FILE
	echo "SDR_OOT_DIR=\"$SDR_OOT_DIR\"" >> $SDR_OOT_BUILDER_FILE
	echo "cd \$SDR_INSTALL_BASE" >> $SDR_OOT_BUILDER_FILE
	echo "source \$SDR_INSTALL_BASE/setup.env" >> $SDR_OOT_BUILDER_FILE
	echo "cd \$1" >> $SDR_OOT_BUILDER_FILE

	echo "if [ -d \"build/\" ]; then" >> $SDR_OOT_BUILDER_FILE
	echo "    echo \"[ INFO ] - Build folder found, rebuilding...\"" >> $SDR_OOT_BUILDER_FILE
	echo "    cd build" >> $SDR_OOT_BUILDER_FILE
	echo "    make uninstall" >> $SDR_OOT_BUILDER_FILE
	echo "    cd .." >> $SDR_OOT_BUILDER_FILE
	echo "    rm -rvf build/" >> $SDR_OOT_BUILDER_FILE
	echo "fi" >> $SDR_OOT_BUILDER_FILE


	echo "mkdir build" >> $SDR_OOT_BUILDER_FILE
	echo "cd build" >> $SDR_OOT_BUILDER_FILE
	echo "eval \$SDR_CMAKE_COMMAND" >> $SDR_OOT_BUILDER_FILE
	echo "make -j${BUILD_CORES}" >> $SDR_OOT_BUILDER_FILE
	echo "make install" >> $SDR_OOT_BUILDER_FILE
	chmod +x $SDR_OOT_BUILDER_FILE
}

create_dirs
write_env_file
write_oot_builder
install_uhd
install_gr
