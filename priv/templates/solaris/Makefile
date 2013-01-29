# requires GNU make
PKG		 = {{solaris_pkgname}}
APP		 = {{package_name}}
# possible ARCH values are i386, sparc, all
DISTRO		 = $(shell head -1 /etc/release|awk \
		   '{if ($$1 == "OmniOS") {print $$1} else {print "Solaris"}}')
KERNEL		 = $(shell uname -r)
SOLARIS_VER	?= $(shell echo "$(KERNEL)" | sed -e 's/^5\.//')
PKGFILE		 = $(PKG_NAME)-$(PKG_VERSION)-$(DISTRO)$(SOLARIS_VER)-$(ARCH).pkg

build: buildrel depend pkginfo prototype
	cp $(PKGERDIR)/copyright $(PKGERDIR)/preinstall $(PKGERDIR)/*.preserve .
	mkdir -p pkgbuild ../packages
	pkgmk -o -d pkgbuild -a $(ARCH)
	touch ../packages/$(PKGFILE)
	pkgtrans -s pkgbuild ../packages/$(PKGFILE) $(PKG)
	rm -r pkgbuild/$(PKG)
	gzip ../packages/$(PKGFILE)
	chmod 0644 ../packages/$(PKGFILE).gz
	@echo
	@echo Wrote: ../packages/$(PKGFILE).gz
	@echo
	cd ../packages && echo "`digest -a sha256 $(PKGFILE).gz`  $(PKGFILE).gz" > $(PKGFILE).gz.sha

# Build the release we need to package
buildrel:
	@# Make sure we set our EUID properly
	@# Ye Olde Bourne Shell on Solaris means we have to do it old school
	echo "Using `which erl` to build"; \
	$(MAKE) deps rel
	chmod 0755 rel/{{package_name}}/{{bin_or_sbin}}/* \
		rel/{{package_name}}/erts-*/bin/*

depend:
	cp $(PKGERDIR)/depend .

pkginfo:
	sed -e 's/@@VERSION@@/$(PKG_VERSION)-$(RELEASE)/g' \
		-e 's/@@PKG@@/$(PKG)/g' \
		-e 's/@@PKGNAME@@/$(APP)/g' \
		< $(PKGERDIR)/pkginfo.tmpl > pkginfo

# NOTE!  The instances of riak below shouldn't change
prototype:
	echo "i pkginfo" > prototype
	echo "i copyright" >> prototype
	echo "i depend" >> prototype
	echo "i preinstall" >> prototype
	echo "i i.preserve" >> prototype
	echo "i r.preserve" >> prototype
	echo '' >> prototype
	pkgproto rel/{{package_name}}={{package_name}} >> prototype
	sed -e "s/ $(LOGNAME) .*$$/ {{package_install_user}} {{package_install_group}}/" \
	    -e 's/f none riak\/etc/e preserve riak\/etc/' prototype > prototype.tmp && mv prototype.tmp prototype

$(PKGERDIR)/pkgclean:
	rm -rf copyright depend pkgbuild pkginfo prototype

