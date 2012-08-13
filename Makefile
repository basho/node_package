##
## Export all variables to sub-invocation
##
export

OS		= $(shell uname -s)
ERLANG_BIN     ?= $(shell dirname $(shell which erl))

##
## Support RPM and Debian based linux systems
##
ifeq ($(OS),Linux)
ARCH            = $(shell uname -m)
ISRPM 		= $(shell cat /etc/redhat-release 2> /dev/null)
ISDEB		= $(shell cat /etc/debian_version 2> /dev/null)
ifneq ($(ISRPM),)
OSNAME          = RedHat
PKGERDIR	= rpm
BUILDDIR        = rpmbuild
else
ifneq ($(ISDEB),)
OSNAME          = Debian
PKGERDIR	= deb
BUILDDIR        = debuild
endif  # deb
endif  # rpm
endif  # linux

DATE            = $(shell date +%Y-%m-%d)

# Set the version that shows for `<app> version`
VERSIONSTRING   =  $(PKG_NAME) ($(PKG_VERSION) $(DATE)) $(OSNAME) $(ARCH)

# Default the package build version to 1 if not already set
PKG_BUILD      ?= 1

.PHONY: ostype varcheck

## Check required settings before continuing
ostype: varcheck
	$(if $(PKGERDIR),,$(error "Operating system '$(OS)' not supported by node_package"))
	make -f $(PKG_ID)/deps/node_package/priv/templates/$(PKGERDIR)/Makefile.bootstrap

varcheck:
	$(if $(PKG_VERSION),,$(error "Variable PKG_VERSION must be set and exported, see basho/node_package readme"))
	$(if $(PKG_ID),,$(error "Variable PKK_ID must be set and exported, see basho/node_package readme"))
