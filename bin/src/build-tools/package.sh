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

build_package() {
	PACKAGE_DIR="${1}"
	RESULT_DIR="${2}"
	LOCAL_REPO_DIR="${3}"
	ARCH="${4}"
	DEST_ARCH="${5}"

	DOCKER="$(choose_application docker)" || error "docker not found"

	${DOCKER} \
		run \
		--rm \
		-v "${RESULT_DIR}":/buildd \
		-v "${PACKAGE_DIR}":/buildd/sources \
		-v "${LOCAL_REPO_DIR}":/buildd/local-repo \
		-e RELENG_FULL_BUILD=yes \
		-e RELENG_HOST_ARCH="${DEST_ARCH}" \
		-e EXTRA_REPOS="deb [trusted=yes] file:///buildd/local-repo/ ./" \
		quay.io/droidian/build-essential:${DROIDIAN_RELEASE}-${ARCH} \
		/bin/sh -c 'cd /buildd/sources && releng-build-package'
}

parse_source_name_from_changes() {
	CHANGES="${1}"

	grep -oP "Source: .+" "${CHANGES}" | awk '{ print $2 }'
}

parse_version_from_changes() {
	CHANGES="${1}"

	grep -oP "Version: .+" "${CHANGES}" | awk '{ print $2 }'
}

import_and_sign_packages() {
	RESULT_DIR="${1}"
	LOCAL_REPO_DIR="${2}"
	GPG_HOMEDIR="${3}"
	PACKAGE_NAME="${4}"
	PACKAGE_VERSION="${5}"

	DPKG_SCANPACKAGES=$(choose_application dpkg-scanpackages) || error "dpkg-scanpackages not found"
	APT_FTPARCHIVE=$(choose_application apt-ftparchive) || error "apt-ftparchive not found"
	GPG=$(choose_application gpg) || error "gpg not found"
	GIT=$(choose_application git) || error "git not found"

	find \
		"${RESULT_DIR}" \
		-maxdepth 1 \
		-type f \
		-name \*.deb \
		-exec mv -fv \{\} "${LOCAL_REPO_DIR}" \;

	(
		cd "${LOCAL_REPO_DIR}" \
		&& ${DPKG_SCANPACKAGES} . /dev/null > Packages \
		&& ${APT_FTPARCHIVE} release . > Release \
		&& ${GPG} --homedir ${GPG_HOMEDIR} -a --yes --clearsign --output InRelease --detach-sign Release \
		&& ${GIT} add . \
		&& ${GIT} commit -sm "[apt] Import ${PACKAGE_NAME} version ${PACKAGE_VERSION}"
	)
}
