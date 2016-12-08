#!/bin/bash -e

export USER="willyhu"
export TMPDIR="/var/tmp/"
export VERSION="$(date +%Y%m%d).01"
export ATLAS_TOKEN="CEkrX3I6lPqBGw.atlasv1.PlyK4v7zfFV4DYSEMlYjfQ7bZbBh9vyQnfyoBs6irKWicPJTUR1l2TEXXpKIQxPOwvc"
export PACKER_LOG=1
export LOG_DIR="./build_logs/"


create_atlas_box() {
  if wget -O /dev/null "https://atlas.hashicorp.com/api/v1/box/$USER/$NAME" 2>&1 | grep -q 'ERROR 404'; then
    #Create box, because it doesn't exists
    echo "*** Creating box: ${NAME}, Short Description: $SHORT_DESCRIPTION"
    curl -s https://atlas.hashicorp.com/api/v1/boxes -X POST -d box[name]="$NAME" -d box[short_description]="${SHORT_DESCRIPTION}" -d box[is_private]=false -d access_token="$ATLAS_TOKEN" > /dev/null
  fi
}

remove_atlas_box() {
  echo "*** Removing box: $USER/$NAME"
  curl -s https://atlas.hashicorp.com/api/v1/box/$USER/$NAME -X DELETE -d access_token="$ATLAS_TOKEN"
}

upload_boxfile_to_atlas() {
  #Get the Current Vrsion before uploading anything
  echo "*** Getting current version of the box (if exists)"
  CURRENT_VERSION=$(curl -s https://atlas.hashicorp.com/api/v1/box/$USER/$NAME -X GET -d access_token="$ATLAS_TOKEN" | jq -r ".current_version.version")
  echo "*** Cureent version of the box: $CURRENT_VERSION"
  curl -sS https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/versions -X POST -d version[version]="$VERSION" -d access_token="$ATLAS_TOKEN" > /dev/null
  curl -sS https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$VERSION -X PUT -d version[description]="$DESCRIPTION" -d access_token="$ATLAS_TOKEN" > /dev/null
  curl -sS https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$VERSION/providers -X POST -d provider[name]='libvirt' -d access_token="$ATLAS_TOKEN" > /dev/null
  UPLOAD_PATH=$(curl -sS https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$VERSION/provider/libvirt/upload?access_token=$ATLAS_TOKEN | jq -r '.upload_path')
  echo "*** Uploading \"${NAME}-libvirt.box\" to $UPLOAD_PATH as version [$VERSION]"
  curl -s -X PUT --upload-file ${NAME}-libvirt.box $UPLOAD_PATH
  curl -s https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$VERSION/release -X PUT -d access_token="$ATLAS_TOKEN" > /dev/null
  # Check if uploaded file really exists
  if curl --output /dev/null --silent --head --fail "https://atlas.hashicorp.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box"; then
    echo "*** File \"https://atlas.hashicorp.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box\" is reachable and exists..."
  else
    echo "*** File \"https://atlas.hashicorp.com/$USER/boxes/$NAME/versions/$VERSION/providers/libvirt.box\" does not exists !!!"
    exit 1
  fi
  #Remove previous version (always keep just one - latest version - recently uploaded)
  if [ "$CURRENT_VERSION" != "null" ]; then
    echo "*** Removing previous version: https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$CURRENT_VERSION"
    curl -s https://atlas.hashicorp.com/api/v1/box/$USER/$NAME/version/$CURRENT_VERSION -X DELETE -d access_token="$ATLAS_TOKEN" > /dev/null
  fi

}

render_template() {
  eval "echo \"$(cat $1)\""
}

packer_build() {
  PACKER_FILE=$1; shift

  /usr/local/bin/packer build -color=false $PACKER_FILE | tee "${LOG_DIR}/${NAME}-packer.log"
  create_atlas_box
  upload_boxfile_to_atlas
  rm -v ${NAME}-libvirt.box
}

build_ubuntu_16_04() {
  export UBUNTU_VERSION="16.04.1"
  export UBUNTU_ARCH="amd64"
  export UBUNTU_TYPE="server"
  export NAME="ubuntu-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
  export DESCRIPTION=$(render_template ubuntu-${UBUNTU_TYPE}.md)
  export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_VERSION::5} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt"

  packer_build ubuntu-${UBUNTU_TYPE}.json
}

build_ubuntu_14_04() {
  export UBUNTU_VERSION="14.04.5"
  export UBUNTU_ARCH="amd64"
  export UBUNTU_TYPE="server"
  export NAME="ubuntu-${UBUNTU_VERSION::5}-${UBUNTU_TYPE}-${UBUNTU_ARCH}"
  export DESCRIPTION=$(render_template ubuntu-${UBUNTU_TYPE}.md)
  export SHORT_DESCRIPTION="Ubuntu ${UBUNTU_VERSION::5} ${UBUNTU_TYPE} (${UBUNTU_ARCH}) for libvirt"

  packer_build ubuntu-${UBUNTU_TYPE}.json
}

build_centos7() {
  export CENTOS_VERSION="7"
  export CENTOS_TAG="1511"
  export CENTOS_ARCH="x86_64"
  export CENTOS_TYPE="NetInstall"
  export NAME="centos-${CENTOS_VERSION}-${CENTOS_ARCH}"
  export DESCRIPTION=$(render_template my-centos${CENTOS_VERSION}.md)
  export SHORT_DESCRIPTION="CentOS ${CENTOS_VERSION} ${CENTOS_ARCH} for libvirt"

  packer_build centos${CENTOS_VERSION}.json
}


#######
# Main
#######

main() {
  build_centos7
  #build_ubuntu_16_04
}

main
