##
## Export all variables to sub-invocation
##
export

OS		= $(shell uname -s)
ERLANG_BIN	?= $(shell dirname $(shell which erl))

##
## Support RPM and Debian based linux systems
##
ifeq ($(OS),Linux)
ARCH		= $(shell uname -m)
ISRPM		= $(shell cat /etc/redhat-release 2> /dev/null)
ISDEB		= $(shell cat /etc/debian_version 2> /dev/null)
ifneq ($(ISRPM),)
OSNAME= RedHat
PKGERDIR	= rpm
BUILDDIR	= rpmbuild
else
ifneq ($(ISDEB),)
OSNAME		= Debian
PKGERDIR	= deb
BUILDDIR	= debuild
endif  # deb
endif  # rpm
endif  # linux

ifeq ($(OS),Darwin)          # OSX
OSNAME		= OSX
ARCH		= $(shell uname -m)
PKGERDIR	= osx
BUILDDIR	= osxbuild
endif

ifeq ($(OS),FreeBSD)
OSNAME		= FreeBSD
ARCH		= $(shell uname -m)
PKGERDIR	= fbsd
BUILDDIR	= fbsdbuild
endif

ifeq ($(OS),SunOS)
OSNAME		= FreeBSD
ARCH		= $(shell uname -p)
PKGERDIR	= solaris
BUILDDIR	= solarisbuild
endif

DATE            = $(shell date +%Y-%m-%d)

# Default the package build version to 1 if not already set
PKG_BUILD      ?= 1

.PHONY: ostype varcheck

## Check required settings before continuing
ostype: varcheck
	$(if $(PKGERDIR),,$(error "Operating system '$(OS)' not supported by node_package"))
	$(MAKE) -f $(PKG_ID)/deps/node_package/priv/templates/$(PKGERDIR)/Makefile.bootstrap

varcheck:
	$(if $(PKG_VERSION),,$(error "Variable PKG_VERSION must be set and exported, see basho/node_package readme"))
	$(if $(PKG_ID),,$(error "Variable PKK_ID must be set and exported, see basho/node_package readme"))
