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

setup_gpg() {
	DESTDIR="${1}"
	DEVICE_SLUG="${2}"

	GPG=$(choose_application gpg) || error "Unable to find gpg"

	homedir="${DESTDIR}/private/gpg"

	mkdir -p "${homedir}"
	chmod 700 "${homedir}"

	${GPG} \
		--homedir "${homedir}" \
		--batch \
		--quick-gen-key \
		--passphrase "" \
		"Community port for ${DEVICE_SLUG} automatic signing key" \
		rsa4096 sign never \
		|| error "Unable to create gpg key"

	# Export
	${GPG} \
		--homedir "${homedir}" \
		--export \
		> "${DESTDIR}/private/gpg_public.gpg" \
		|| error "Unable to export public gpg key"
}
