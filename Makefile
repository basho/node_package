##
## Export all variables to sub-invocation
##
export

OS		= $(shell uname -s)

ifeq ($(OS),Linux)
DISTRO		= $(shell cat /etc/redhat-release 2> /dev/null)
ifeq ($(DISTRO),)
PKGERDIR	= deb
else
PKGERDIR	= rpm
endif
endif

ifeq ($(OS),SunOS)
PKGERDIR	= solaris
endif

ifeq ($(OS),Darwin)
PKGERDIR	= osx
endif

.PHONY: ostype

ostype:
	$(if $(PKGERDIR),,$(error "Operating system '$(OS)' not supported by node_package"))
	make -f priv/templates/$(PKGERDIR)/Makefile.bootstrap