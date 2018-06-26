#!/bin/bash -x

mkdir -p /srv/nfs/user-vols/pv{1..200}

for pvnum in {1..50} ; do
  echo /srv/nfs/user-vols/pv${pvnum} *\(rw,root_squash\) >> /etc/exports.d/openshift-uservols.exports
  chown -R nfsnobody.nfsnobody  /srv/nfs
  chmod -R 777 /srv/nfs
done

systemctl restart nfs-server


volsize="5Gi"
mkdir /root/pvs
for volume in pv{1..25} ; do
cat << EOF > /root/pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce" ],
    "nfs": {
        "path": "/srv/nfs/user-vols/${volume}",
        "server": "oselab.example.com"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
echo "Created def file for ${volume}";
done;

volsize="10Gi"
for volume in pv{26..50} ; do
cat << EOF > /root/pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "/srv/nfs/user-vols/${volume}",
        "server": "oselab.example.com"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}";
done;

oc login system:admin

cat /root/pvs/* | oc create -f -
oc get pv

