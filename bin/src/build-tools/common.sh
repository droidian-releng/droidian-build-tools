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

export DROIDIAN_RELEASE="${DROIDIAN_RELEASE:-bookworm}"

info() {
	echo "I: $@"
}

warning() {
	echo "W: $@" >&2
}

error() {
	echo "E: $@" >&2
	exit 1
}

choose_application() {
	for candidate in ${@}; do
		app=$(whereis -b ${candidate} | head -n 1 | awk '{ print $2 }')
		if [ -n "${app}" ]; then
			echo "${app}"
			return 0
		fi
	done

	return 1
}

slugify() {
	echo ${1} \
		| tr '[:upper:]' '[:lower:]' \
		| sed -r 's|[^a-z0-9]+|-|g'
}

noerrors() {
	$@ 2> /dev/null
}

get_author_name() {
	GIT=$(choose_application git) || error "Unable to find git"

	name="$(noerrors ${GIT} config --get user.name)"
	[ -n "${name}" ] || name="${USER}"

	echo "${name}"
}

get_author_email() {
	GIT=$(choose_application git) || error "Unable to find git"

	email="$(noerrors ${GIT} config --get user.email)"
	[ -n "${email}" ] || email="${USER}@$(hostname)"

	echo "${email}"
}
