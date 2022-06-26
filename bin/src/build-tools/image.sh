#
# Copyright 2022 Eugenio Paolantonio (g7)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

source ./src/build-tools/common.sh

setup_image() {
	DESTDIR="${1}"
	VENDOR="${2}"
	NAME="${3}"
	ARCH="${4}"
	APILEVEL="${5}"
	VARIANT="${6}"

	GIT=$(choose_application git) || error "Unable to find git"
	GIT_LFS=$(choose_application git-lfs) || error "Unable to find git-lfs"

	DEVICE_SLUG="${VENDOR}-${NAME}"

	${GIT} \
		clone \
		https://github.com/droidian-images/droidian.git \
		"${DESTDIR}/droidian"

	cat > "${DESTDIR}/droidian/community_devices.yml" <<EOF
# This file has been generated automatically by droidian-new-device

# ${VENDOR} ${NAME}
${VENDOR}_${NAME}:
  type: image
  arch: ${ARCH}
  edition: phosh
  variant: ${VARIANT}
  apilevel: ${APILEVEL}
  use_internal_repository: true

  packages:
    - adaptation-${DEVICE_SLUG}
    - adaptation-${DEVICE_SLUG}-configs
EOF

	(
		cd "${DESTDIR}/droidian" \
		&& ${GIT_LFS} install \
		&& ${GIT} submodule init \
		&& ${GIT} submodule update \
		&& ${GIT} add community_devices.yml \
		&& ${GIT} commit -sm "[droidian] Add generated device specification for community adaptation ${DEVICE_SLUG}" \
		&& ${GIT} remote rename origin upstream
	)

}
