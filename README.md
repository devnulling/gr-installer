# gr-installer
This is a basic bash script that will perform a UHD/GR install for a given commit combo to a local directory.

## A note about deps and error checking

There is no dependency management built in, however there is an option `--deps` which will install the basic deps for UHD/GR on Ubuntu 18.04. If you do not have a required dependency installed for an OOT, it will fail to install. Dependencies must be handled manually. 


## Usage
```    
mkdir -p ~/sdr/installs
cd ~/sdr
git clone https://github.com/devnulling/gr-installer .
chmod +x sdr.sh
./sdr.sh -u v3.14.1.1 -g maint-3.7
```
### Using an install
```
cd ~/sdr/installs/$INSTALL_PREFIX
source setup.env
gnuradio-companion # or uhd_usrp_probe
```

### Installing OOTs
```
cd ~/sdr/installs/$INSTALL_PREFX
cd oots/
git clone https://github.com/$author/gr-oot
cd ..
./oot.sh oots/gr-oot 
```

Running `./oot.sh` against an OOT that is already installed (with a `gr-oot/build` directory) will uninstall and rebuild it.

# TODO
* Add support for py3 (py2.7 paths are hard coded)
* Add support for private repos
* Add fetch.sh script for common OOTs

