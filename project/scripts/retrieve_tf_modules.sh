#!/usr/bin/env bash
set -Eeuo pipefail
# set -x # print each command before executing

FILMDROP_TERRAFORM_RELEASE=$1

wget -qO- https://github.com/Element84/filmdrop-aws-tf-modules/archive/refs/tags/${FILMDROP_TERRAFORM_RELEASE}.tar.gz | tar xvz
mkdir -p modules
mkdir -p profiles
cp filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}/filmdrop.tf .
cp filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}/providers.tf .
cp filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}/inputs.tf .
cp -r filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}/modules .
cp -r filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}/profiles .
rm -rf filmdrop-aws-tf-modules-${FILMDROP_TERRAFORM_RELEASE:1}