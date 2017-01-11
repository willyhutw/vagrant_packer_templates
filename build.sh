#!/bin/bash -e

export PACKER_LOG=1
export LOG_DIR="./build_logs/"

render_template() {
  eval "echo \"$(cat $1)\""
}

packer_build() {
  PACKER_FILE=$1; shift
  /usr/local/bin/packer build -color=false $PACKER_FILE | tee "${LOG_DIR}/${NAME}-packer.log"
}

export_ubuntu16() {
  export UBUNTU_VERSION="16.04.1"
  export UBUNTU_MAIN_VERSION="16"
  export UBUNTU_ARCH="amd64"
  export UBUNTU_TYPE="server"
  export NAME="ubuntu-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
  export DESCRIPTION=$(render_template ubuntu-${UBUNTU_TYPE}.md)
  export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_VERSION::5} ${UBUNTU_TYPE} (${UBUNTU_ARCH})"

}

export_centos7() {
  export CENTOS_VERSION="7"
  export CENTOS_TAG="1511"
  export CENTOS_ARCH="x86_64"
  export CENTOS_TYPE="NetInstall"
  export NAME="centos-${CENTOS_VERSION}-${CENTOS_ARCH}"
  export DESCRIPTION=$(render_template my-centos${CENTOS_VERSION}.md)
  export SHORT_DESCRIPTION="CentOS ${CENTOS_VERSION} ${CENTOS_ARCH}"

}

#######
# Main
#######

export_ubuntu16
packer_build ubuntu${UBUNTU_MAIN_VERSION}-virtualbox.json
#packer_build ubuntu${UBUNTU_MAIN_VERSION}-libvirt.json

#export_centos7
#packer_build centos${CENTOS_VERSION}-virtualbox.json
#packer_build centos${CENTOS_VERSION}-libvirt.json

