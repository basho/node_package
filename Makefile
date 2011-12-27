##
## Export all variables to sub-invocation
##
export

OS		= $(shell uname -s)

##
## Support RPM and Debian based linux systems
##
ifeq ($(OS),Linux)
ISRPM 		= $(shell cat /etc/redhat-release 2> /dev/null)
ISDEB		= $(shell cat /etc/debian_version 2> /dev/null)
ifneq ($(ISRPM),)
PKGERDIR	= rpm
else
ifneq ($(ISDEB),)
PKGERDIR	= deb
endif  # deb
endif  # rpm
endif  # linux

ifeq ($(OS),SunOS)
PKGERDIR	= solaris
endif

ifeq ($(OS),Darwin)
PKGERDIR	= osx
endif

.PHONY: ostype

ostype:
	$(if $(PKGERDIR),,$(error "Operating system '$(OS)' not supported by node_package"))
	make -f $(PKG_ID)/deps/node_package/priv/templates/$(PKGERDIR)/Makefile.bootstrap