droidian-build-tools
====================

Helpers for Droidian community ports

Installation
------------

Just clone this repository, and add the bin/ directory to your `PATH`. For example:

	git clone https://github.com/droidian-releng/droidian-build-tools.git
	cd droidian-build-tools
	echo "PATH=${PWD}/bin:\${PATH}" >> ~/.bashrc

Tools
-----

# droidian-new-device

Creates a skeleton for a new device

# droidian-build-package

Builds a package using the Droidian toolchain, and imports it into your device-specific
repository.
