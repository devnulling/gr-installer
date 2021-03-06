#!/bin/bash

# Instructions
# make sure /home/$user/sdr/installs is a valid folder
# copy this file to /home/$user/sdr/sdr.sh
# chmod +x /home/$user/sdr/sdr.sh
# cd /home/$user/sdr
# ./sdr.sh -u $UHD_VERSION -g $GR_VERSION
# ./sdr.sh -u v3.14.1.1 -g maint-3.7

# TODO
# test dry run / clone only options 

set -e

RFNOC_INSTALL=NO
E300_INSTALL=NO
UHD_VERSION="master"
GR_VERSION="master"
BUILD_CORES=7
GR_FULL_INSTALL=NO
INSTALL_DEPS=NO
EXTRA_PREFIX=""
EXTRA_PREIFX_ENABLED=NO
DRY_RUN=NO
FETCH_SOURCES=NO
INSTALL_TARGET="installs"
BASE_TARGET="sdr"
GR_BASE_REPO="gnuradio/gnuradio"
UHD_BASE_REPO="ettusresearch/uhd"
GR38=NO
GR_BRANCH="master"
GRPR=NO
PR=0

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
    # extra prefix
    -p|--prefix)
    EXTRA_PREFIX="$2"
    EXTRA_PREIFX_ENABLED=YES
    shift
    shift
    ;;
    #dry
    --dry)
    DRY_RUN=YES
    shift 
    ;;
    #dry
    --fetch)
    FETCH_SOURCES=YES
    shift 
    ;;
    # target
    -t|--target)
    INSTALL_TARGET="$2"
    shift
    shift
    ;;
    # base target
    -b|--base)
    BASE_TARGET="$2"
    shift
    shift
    ;;
    # GR repo
    -m|--gr_repo)
    GR_BASE_REPO="$2"
    shift
    shift
    ;;
    # UHD repo
    -n|--uhd_repo)
    UHD_BASE_REPO="$2"
    shift
    shift
    ;;
    #dry
    --gr38)
    GR38=YES
    shift 
    ;;
    # GNU Radio version
    --gr_branch)
    GR_BRANCH="$2"
    shift
    shift
    ;;
    #dry
    --grpr)
    GRPR=YES
    shift 
    ;;
    # GNU Radio version
    --pr)
    PR="$2"
    shift
    shift
    ;;
    #dry
esac
done

if [ "$GRPR" == "YES" ]; then
	UHD_VERSION="v3.15.0.0"
	GR38=YES
	GR_FULL_INSTALL=YES
	GR_VERSION="$(/usr/bin/python3 /home/user/sdr/gethub.py -p ${PR} -g branch)"  #branch name
	GR_BRANCH="$(/usr/bin/python3 /home/user/sdr/gethub.py -p ${PR} -g branch)" #branch name
	GR_BASE_REPO="$(/usr/bin/python3 /home/user/sdr/gethub.py -p ${PR} -g repo)" # user/gnuradio

	echo "BUILDING"
	echo "--------------"
	echo "Repo: ${GR_BASE_REPO}"
	echo "Branch: ${GR_BRANCH}"
	echo "--------------"
fi
SDR_BASE_DIR="/home/$USER/$BASE_TARGET"
SDR_INSTALL_TARGET="$SDR_BASE_DIR/$INSTALL_TARGET"

if [ ! -d "$SDR_BASE_DIR" ]; then
    echo "$SDR_BASE_DIR does not exist, creating the folder"
    mkdir -p $SDR_BASE_DIR
fi

if [ ! -d "$SDR_INSTALL_TARGET" ]; then
    echo "$SDR_INSTALL_TARGET does not exist, creating the folder"
    mkdir -p $SDR_INSTALL_TARGET
fi

if [ "$INSTALL_DEPS" == "YES" ]; then
	# install deps
	sudo apt-get -y install git swig cmake doxygen build-essential libboost-all-dev libtool libusb-1.0-0 libusb-1.0-0-dev libudev-dev libncurses5-dev libfftw3-bin libfftw3-dev libfftw3-doc libcppunit-1.14-0 libcppunit-dev libcppunit-doc ncurses-bin cpufrequtils python-numpy python-numpy-doc python-numpy-dbg python-scipy python-docutils qt4-bin-dbg qt4-default qt4-doc libqt4-dev libqt4-dev-bin python-qt4 python-qt4-dbg python-qt4-dev python-qt4-doc python-qt4-doc libqwt6abi1 libfftw3-bin libfftw3-dev libfftw3-doc ncurses-bin libncurses5 libncurses5-dev libncurses5-dbg libfontconfig1-dev libxrender-dev libpulse-dev swig g++ automake autoconf libtool python-dev libfftw3-dev libcppunit-dev libboost-all-dev libusb-dev libusb-1.0-0-dev fort77 libsdl1.2-dev python-wxgtk3.0 git libqt4-dev python-numpy ccache python-opengl libgsl-dev python-cheetah python-mako python-lxml doxygen qt4-default qt4-dev-tools libusb-1.0-0-dev libqwtplot3d-qt5-dev pyqt4-dev-tools python-qwt5-qt4 cmake git wget libxi-dev gtk2-engines-pixbuf r-base-dev python-tk liborc-0.4-0 liborc-0.4-dev libasound2-dev python-gtk2 libzmq3-dev libzmq5 python-requests python-sphinx libcomedi-dev python-zmq libqwt-dev libqwt6abi1 python-six libgps-dev libgps23 gpsd gpsd-clients python-gps python-setuptools
	echo "Deps installed, re-run with UHD/GR versions"
	exit 0	
fi

SDR_UHD_VERSION=$UHD_VERSION
SDR_GR_VERSION=$GR_VERSION

if [ "$RFNOC_INSTALL" == "YES" ] && [ "$EXTRA_PREIFX_ENABLED" == "YES" ]; then
	SDR_INSTALL_UID="${EXTRA_PREFIX}_rfnoc_${SDR_UHD_VERSION}_${SDR_GR_VERSION}"

elif [ "$RFNOC_INSTALL" == "YES" ] && [ "$EXTRA_PREIFX_ENABLED" == "NO" ]; then
	SDR_INSTALL_UID="rfnoc_${SDR_UHD_VERSION}_${SDR_GR_VERSION}"

elif [ "$RFNOC_INSTALL" == "NO" ] && [ "$EXTRA_PREIFX_ENABLED" == "YES" ]; then
	SDR_INSTALL_UID="${EXTRA_PREFIX}_${SDR_UHD_VERSION}_${SDR_GR_VERSION}"

else
	SDR_INSTALL_UID="${SDR_UHD_VERSION}_${SDR_GR_VERSION}"
fi

if [ "$GRPR" == "YES" ]; then
	SDR_INSTALL_UID="gr_${PR}"
fi


SDR_INSTALL_BASE="$SDR_INSTALL_TARGET/$SDR_INSTALL_UID"
SDR_SRC_TARGET="$SDR_INSTALL_BASE/src"
SDR_UHD_SRC_BASE="$SDR_SRC_TARGET/uhd"
SDR_GR_SRC_BASE="$SDR_SRC_TARGET/gnuradio"
SDR_ENV_FILE="$SDR_INSTALL_BASE/setup.env"
SDR_OOT_DIR="$SDR_INSTALL_BASE/oots"
SDR_OOT_BUILDER_FILE="$SDR_INSTALL_BASE/oot.sh"
SDR_REBUILD_FILE="$SDR_INSTALL_BASE/rebuild.sh"

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
	if [ "$DRY_RUN" == "NO" ] || [ "$FETCH_SOURCES" == "YES" ]; then
		mkdir -p $SDR_BASE_DIR
		mkdir -p $SDR_SRC_TARGET
		mkdir -p $SDR_INSTALL_TARGET
		mkdir -p $SDR_INSTALL_BASE
		mkdir -p $SDR_UHD_SRC_BASE
		mkdir -p $SDR_OOT_DIR
	fi
}

install_uhd(){
	if [ "$DRY_RUN" == "NO" ]; then
		cd $SDR_SRC_TARGET
		check_dir

		git clone --recursive "https://github.com/${UHD_BASE_REPO}" $SDR_UHD_SRC_BASE

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
	else
		echo $SDR_UHD_CMAKE
	fi

	if [ "$DRY_RUN" == "YES" ] || [ "$FETCH_SOURCES" == "YES" ]; then
		cd $SDR_SRC_TARGET
		check_dir

		git clone --recursive "https://github.com/${UHD_BASE_REPO}" $SDR_UHD_SRC_BASE

		cd "$SDR_UHD_SRC_BASE/"
		check_dir

		git checkout $SDR_UHD_VERSION
		git submodule update --init --recursive

		cd "$SDR_UHD_SRC_BASE/host"
		check_dir

		mkdir -p "$SDR_UHD_SRC_BASE/host/build"
		cd "$SDR_UHD_SRC_BASE/host/build"
		check_dir

	fi
}

install_gr(){
	if [ "$DRY_RUN" == "NO" ]; then
		cd $SDR_SRC_TARGET
		check_dir
		git clone --recursive "https://github.com/${GR_BASE_REPO}" $SDR_GR_SRC_BASE
		cd $SDR_GR_SRC_BASE
		check_dir
		#git checkout $SDR_GR_VERSION
		git checkout $GR_BRANCH
		git submodule update --init --recursive
		mkdir -p "${SDR_GR_SRC_BASE}/build"
		cd "${SDR_GR_SRC_BASE}/build"
		check_dir
		
		echo $SDR_GR_CMAKE
		eval $SDR_GR_CMAKE
		make -j${BUILD_CORES} #VERBOSE=ON
		make install
		gnuradio-config-info --version
	else
		echo $SDR_GR_CMAKE
	fi

	if [ "$DRY_RUN" == "YES" ] || [ "$FETCH_SOURCES" == "YES" ]; then
		cd $SDR_SRC_TARGET
		check_dir
		git clone --recursive "https://github.com/${GR_BASE_REPO}" $SDR_GR_SRC_BASE
		cd $SDR_GR_SRC_BASE
		check_dir
		#git checkout $SDR_GR_VERSION
		git checkout $GR_BRANCH
		git submodule update --init --recursive
		mkdir -p "${SDR_GR_SRC_BASE}/build"
		cd "${SDR_GR_SRC_BASE}/build"
		check_dir
		
	fi
}

write_env_file(){
	if [ "$DRY_RUN" == "NO" ] || [ "$FETCH_SOURCES" == "YES" ]; then
		SDR_BASE_PATH="$SDR_INSTALL_BASE"
		SDR_PATH="$SDR_BASE_PATH/bin:$PATH"
		SDR_LD_LIBRARY_PATH="$SDR_BASE_PATH/lib:$LD_LIBRARY_PATH"

		if [ "$GR38" == "NO" ]; then
			SDR_PYTHONPATH_1="$SDR_BASE_PATH/lib/python2.7/site-packages"
			SDR_PYTHONPATH_2="$SDR_BASE_PATH/lib/python2.7/dist-packages"
		else 
			SDR_PYTHONPATH_1="$SDR_BASE_PATH/lib/python3/site-packages"
			SDR_PYTHONPATH_2="$SDR_BASE_PATH/lib/python3/dist-packages"
		fi

		SDR_PKG_CONFIG="$SDR_BASE_PATH/lib/pkgconfig:$PKG_CONFIG_PATH"
		SDR_GR_BLOCK_PATH="$SDR_BASE_PATH/share/gnuradio/grc/blocks"
		SDR_RFNOC_PATH="$SDR_BASE_PATH/share/uhd/rfnoc/"
		SDR_LIBRARY_PATH="$SDR_BASE_PATH/lib"

		echo "Writing Environment File: $SDR_ENV_FILE"
		echo "export BASE_PATH=$SDR_BASE_PATH" > $SDR_ENV_FILE
		echo "export PATH=$SDR_PATH" >> $SDR_ENV_FILE
		echo "export LD_LIBRARY_PATH=$SDR_LD_LIBRARY_PATH" >> $SDR_ENV_FILE
		echo "export PYTHONPATH=$SDR_PYTHONPATH_1:$SDR_PYTHONPATH_2" >> $SDR_ENV_FILE
		echo "export PKG_CONFIG_PATH=$SDR_PKG_CONFIG" >> $SDR_ENV_FILE
		echo "export GRC_BLOCKS_PATH=$SDR_GR_BLOCK_PATH" >> $SDR_ENV_FILE
		echo "export UHD_RFNOC_DIR=$SDR_RFNOC_PATH" >> $SDR_ENV_FILE
		echo "export LIBRARY_PATH=$SDR_LIBRARY_PATH" >> $SDR_ENV_FILE
	fi


}

write_oot_builder(){
	if [ "$DRY_RUN" == "NO" ] || [ "$FETCH_SOURCES" == "YES" ]; then
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

		echo $SDR_UHD_CMAKE > $SDR_REBUILD_FILE
		echo $SDR_GR_CMAKE >> $SDR_REBUILD_FILE
	fi
}

create_dirs
write_env_file
write_oot_builder
install_uhd
install_gr
