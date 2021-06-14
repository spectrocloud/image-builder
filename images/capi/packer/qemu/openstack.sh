#!/usr/bin/bash

set -euox pipefail

apt update
DEBIAN_FRONTEND=noninteractive apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst cpu-checker libguestfs-tools libosinfo-bin make unzip python3-pip jq

ensure_aws_bin() {
  if ! command -v aws >/dev/null 2>&1; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-2.0.30.zip" -o "awscliv2.zip"

    if [ -d "./aws" ]
    then
        echo "aws cli folder exists, removing"
        rm -rf ./aws
    else
        echo "aws cli folder not present"
    fi


    unzip awscliv2.zip
    sudo ./aws/install

    which aws
  else

    echo "aws cli already installed"
  fi
}

ensure_aws_bin


if [ -d "./image-builder" ]
then
   echo "image-builder project exists"
   rm -rf ./image-builder
else
   echo "image-builde not present"
fi

export PATH=/root/.local/bin:$PATH
export PATH=/home/ubuntu/image-builder/images/capi/.local/bin:$PATH

git clone https://github.com/kubernetes-sigs/image-builder.git

cd image-builder/images/capi/

export K8S_VERSION="1.20.7"

export K8S_DEB_VERSION="${K8S_VERSION}-00"

if [[ "${K8S_VERSION}" =~ ^[0-9]\.[0-9]{0,3}\.[0-9]{0,3}$ ]]; then
    echo "Valid k8s version"
else
    echo "Invalid k8s version"
    exit 1
fi

export K8S_SERIES=`echo "${K8S_VERSION}" | awk 'BEGIN {FS="."; OFS="."} {print $1,$2}'`
export IMAGE_K8S_VERSION=`echo "${K8S_VERSION}" | awk 'BEGIN {FS="."; OFS=""} {print $1,$2,$3}'`
export IMAGE_OS_VERSION="18045"
export OUTPUT_OS_VERSION="1804"

cat ./packer/qemu/qemu-ubuntu-1804.json | jq ". + {\"kubernetes_deb_version\": \"${K8S_DEB_VERSION}\"}" > ./packer/qemu/qemu-ubuntu-1804.json.tmp
mv ./packer/qemu/qemu-ubuntu-1804.json.tmp ./packer/qemu/qemu-ubuntu-1804.json

cat ./packer/qemu/qemu-ubuntu-1804.json | jq ". + {\"kubernetes_semver\": \"v${K8S_VERSION}\"}" > ./packer/qemu/qemu-ubuntu-1804.json.tmp
mv ./packer/qemu/qemu-ubuntu-1804.json.tmp ./packer/qemu/qemu-ubuntu-1804.json

cat ./packer/qemu/qemu-ubuntu-1804.json | jq ". + {\"kubernetes_series\": \"v${K8S_SERIES}\"}" > ./packer/qemu/qemu-ubuntu-1804.json.tmp
mv ./packer/qemu/qemu-ubuntu-1804.json.tmp ./packer/qemu/qemu-ubuntu-1804.json


cat ./packer/qemu/qemu-ubuntu-1804.json

make deps-qemu
# export PACKER_LOG=3
make build-qemu-ubuntu-1804

echo $HOME

mkdir -p /root/.aws

echo "[goldenci-bucket]
aws_access_key_id = AKIAWECVDHOP5UHD4H4X
aws_secret_access_key = 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
region =  us-east-1" > /root/.aws/credentials

export AWS_PROFILE=goldenci-bucket

aws s3api put-object --acl public-read --bucket openstackgoldenimage --key "u-${IMAGE_OS_VERSION}-0-${IMAGE_K8S_VERSION}-0.img" --body ./output/ubuntu-${OUTPUT_OS_VERSION}-kube-v${K8S_VERSION}/ubuntu-${OUTPUT_OS_VERSION}-kube-v${K8S_VERSION}

