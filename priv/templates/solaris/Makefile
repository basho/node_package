# requires GNU make
PKG		 = {{solaris_pkgname}}
APP		 = {{package_name}}
# possible ARCH values are i386, sparc, all
KERNEL		 = $(shell uname -r)
SOLARIS_VER	?= $(shell echo "$(KERNEL)" | sed -e 's/^5\.//')
PKGFILE		 = $(PKG)-$(PKG_VERSION)-$(DISTRO)$(SOLARIS_VER)-$(ARCH).pkg

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
# Make sure to copy binaries to {{bin_or_sbin}}
buildrel:
	@# Make sure we set our EUID properly
	@# Ye Olde Bourne Shell on Solaris means we have to do it old school
	echo "Using `which erl` to build"; \
	OVERLAY_VARS="overlay_vars=../solaris/vars.config" $(MAKE) rel
	chmod 0755 rel/{{package_install_name}}/bin/* \
		rel/{{package_install_name}}/erts-*/bin/*
	if [ "{{bin_or_sbin}}" != "bin" ]; then \
	   mv rel/{{package_install_name}}/bin rel/{{package_install_name}}/{{bin_or_sbin}}; fi

depend:
	cp $(PKGERDIR)/depend .

pkginfo:
	sed -e 's/@@VERSION@@/$(PKG_VERSION)-$(RELEASE)/g' \
		-e 's/@@PKG@@/$(PKG)/g' \
		-e 's/@@PKGNAME@@/$(APP)/g' \
		< $(PKGERDIR)/pkginfo.tmpl > pkginfo

prototype:
	echo "i pkginfo" > prototype
	echo "i copyright" >> prototype
	echo "i depend" >> prototype
	echo "i preinstall" >> prototype
	echo "i i.preserve" >> prototype
	echo "i r.preserve" >> prototype
	echo '' >> prototype
	pkgproto rel/{{package_install_name}}={{package_install_name}} >> prototype
	sed -e "s/ $(LOGNAME) .*$$/ root bin/" \
		-e "s/\([f|d]\) none {{package_install_name}}\/log\(.*\) \(.*\) root bin/\1 none {{package_install_name}}\/log\2 \3 {{package_install_user}} {{package_install_group}}/" \
		-e "s/\([f|d]\) none {{package_install_name}}\/data\(.*\) \(.*\) root bin/\1 none {{package_install_name}}\/data\2 \3 {{package_install_user}} {{package_install_group}}/" \
	    -e 's/f none {{package_install_name}}\/etc/e preserve {{package_install_name}}\/etc/' prototype > prototype.tmp && mv prototype.tmp prototype

$(PKGERDIR)/pkgclean:
	rm -rf copyright depend pkgbuild pkginfo prototype
