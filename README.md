### = a rough script for building vagrant box with packer =
<br/>
<br/>

### = before you run =
edit build.sh

then just run <code>./build.sh</code>
<br/>
<br/>

```
.
|-- Vagrantfile-linux.template
|-- http
|   |-- centos
|   |   `-- ks.cfg
|   `-- ubuntu
|       `-- preseed.cfg
|-- scripts
|   |-- linux-common
|   |   |-- cleanup.sh
|   |   `-- vagrant.sh
|   `-- ubuntu
|       `-- update.sh
|-- build.sh
|-- centos7-libvirt.json
|-- centos7-virtualbox.json
|-- ubuntu16-libvirt.json
`-- ubuntu16-virtualbox.json

```

