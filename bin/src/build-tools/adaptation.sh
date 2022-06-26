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

setup_adaptation() {
	DESTDIR="${1}"
	DEVICE_SLUG="${2}"
	ARCH="${3}"
	APILEVEL="${4}"
	VARIANT="${5}"
	GPG_PUBKEY="${6}"

	GIT=$(choose_application git) || error "Unable to find git"

	adaptation_dir="${DESTDIR}/adaptation-${DEVICE_SLUG}"
	adaptation_packaging_dir="${adaptation_dir}/debian"
	adaptation_sparse_dir="${adaptation_dir}/sparse"

	mkdir -p "${adaptation_dir}" "${adaptation_packaging_dir}" "${adaptation_sparse_dir}"

	if [ "${VARIANT}" == "standard" ]; then
		variant_package="adaptation-hybris-api${APILEVEL}"
	else
		variant_package="adaptation-hybris-api${APILEVEL}-${VARIANT}"
	fi

	# Populate sparse content
	mkdir -p "${adaptation_sparse_dir}/usr/lib/adaptation-${DEVICE_SLUG}/trusted.gpg.d"
	cp "${GPG_PUBKEY}" "${adaptation_sparse_dir}/usr/lib/adaptation-${DEVICE_SLUG}/trusted.gpg.d/community-${DEVICE_SLUG}.gpg"

	mkdir -p "${adaptation_sparse_dir}/usr/lib/adaptation-${DEVICE_SLUG}/sources.list.d"
	cat > "${adaptation_sparse_dir}/usr/lib/adaptation-${DEVICE_SLUG}/sources.list.d/community-${DEVICE_SLUG}.list" <<EOF
# You can add here your custom apt repositories
EOF

	# Create packaging
	author="$(get_author_name) <$(get_author_email)>"
	current_year="$(date +%Y)"
	cat > "${adaptation_packaging_dir}/control" <<EOF
Source: adaptation-${DEVICE_SLUG}
Maintainer: ${author}
Section: metapackages
Priority: optional
Build-Depends: debhelper (>= 10),
               debhelper-compat (= 13),
Standards-Version: 4.5.0.3

Package: adaptation-${DEVICE_SLUG}
Architecture: ${ARCH}
Depends: \${misc:Depends},
         ${variant_package},
         adaptation-${DEVICE_SLUG}-configs (= \${binary:Version}),
Description: Community adaptation for ${DEVICE_SLUG} - metapackage

Package: adaptation-${DEVICE_SLUG}-configs
Architecture: ${ARCH}
Depends: \${misc:Depends},
Description: Community adaptation for ${DEVICE_SLUG} - adaptation configurations
EOF

	cat > "${adaptation_packaging_dir}/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: adaptation-${DEVICE_SLUG}
Source: <PLEASE_FILL_HERE>

Files: *
Copyright: ${current_year} ${author}
License: BSD-3-clause

Files: debian/*
Copyright: ${current_year} ${author}
License: BSD-3-clause

License: BSD-3-clause
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

EOF

	cat > "${adaptation_packaging_dir}/rules" <<EOF
#!/usr/bin/make -f

%:
	dh \$@
EOF
	chmod +x "${adaptation_packaging_dir}/rules"

	cat > "${adaptation_packaging_dir}/adaptation-${DEVICE_SLUG}-configs.install" <<EOF
sparse/*
EOF

	cat > "${adaptation_packaging_dir}/adaptation-${DEVICE_SLUG}-configs.dirs" <<EOF
/etc/apt/sources.list.d
/etc/apt/preferences.d
/etc/apt/package-sideload-create.d
/etc/apt/trusted.gpg.d
EOF

	cat > "${adaptation_packaging_dir}/adaptation-${DEVICE_SLUG}-configs.links" <<EOF
/usr/lib/adaptation-${DEVICE_SLUG}/sources.list.d/community-${DEVICE_SLUG}.list /etc/apt/sources.list.d/community-${DEVICE_SLUG}.list
/usr/lib/adaptation-${DEVICE_SLUG}/trusted.gpg.d/community-${DEVICE_SLUG}.gpg /etc/apt/trusted.gpg.d/community-${DEVICE_SLUG}.gpg
EOF

	mkdir -p "${adaptation_packaging_dir}/source"
	echo "3.0 (native)" > "${adaptation_packaging_dir}/source/format"

	(
		cd "${adaptation_dir}" \
		&& ${GIT} init \
		&& ${GIT} add . \
		&& ${GIT} commit -sm "Initial commit" \
		&& ${GIT} branch -M ${DROIDIAN_RELEASE}
	)
}

find_adaptation_info() {
	START_DIR="${1:-${PWD}}"

	cd "${START_DIR}"
	while [ "${PWD}" != "/" ]; do
		if [ -e "${PWD}/droidian-community-adaptation" ]; then
			echo "${PWD}/droidian-community-adaptation"
			return 0
		else
			cd ..
		fi
	done

	return 1
}
