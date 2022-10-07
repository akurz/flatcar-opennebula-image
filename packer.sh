#!/bin/bash

set -eux

flatcar_download_url="http://${FLATCAR_CHANNEL}.release.flatcar-linux.net/amd64-usr/current"

# Fetch Flatcar Linux signing keys.
pushd /tmp
  curl -LO https://www.flatcar-linux.org/security/image-signing-key/Flatcar_Image_Signing_Key.asc
  gpg --import Flatcar_Image_Signing_Key.asc

  # Get latest Flatcar Linux version number.
  curl -Ov ${flatcar_download_url}/version.txt
  curl -Ov ${flatcar_download_url}/version.txt.DIGESTS.asc
  gpg --verify version.txt.DIGESTS.asc
  expected_md5=$(grep version.txt version.txt.DIGESTS.asc | head -n 1)
  if [ "$(md5sum version.txt)" != "$expected_md5" ] ; then
      echo "Invalid MD5 checksum of `version.txt`"
      exit 1
  fi
  . ./version.txt
  flatcar_version=$FLATCAR_VERSION

  # Get MD5 checksum of latest Flatcar Linux iso image.
  curl -Ov ${flatcar_download_url}/flatcar_production_iso_image.iso.DIGESTS.asc
  gpg --verify flatcar_production_iso_image.iso.DIGESTS.asc
  if [ "$?" = "1" ] ; then
      echo "Invalid GPG signature for flatcar_production_iso_image.iso.DIGESTS.asc"
      exit 1
  fi
  flatcar_md5_checksum=$(grep  flatcar_production_iso_image.iso flatcar_production_iso_image.iso.DIGESTS.asc | \
          head -n 1 | \
          awk '{print $1}')

  if [ -r /dev/kvm ] ; then
      accelerator="kvm"
      boot_wait="60s"
  else
      accelerator="none"
      boot_wait="120s"
  fi
  headless="${HEADLESS:-false}"
popd

exec packer $1 \
     -var accelerator=$accelerator \
     -var boot_wait=$boot_wait \
     -var headless=$headless \
     -var flatcar_channel=$FLATCAR_CHANNEL \
     -var flatcar_version=$flatcar_version \
     -var iso_checksum=$flatcar_md5_checksum \
     $2
