
PWD    = $(shell pwd)


ifeq ($(OSNAME),RedHat)
DISTRO = $(shell head -1 /etc/redhat-release| awk \
           '{if ($$0 ~ /CentOS release 5/) { print ".el5."} else { print "." }} ')
INITSCRIPT=rhel.init.script
endif
ifeq ($(OSNAME),SLES)
DISTRO = .SLES$(shell grep VERSION /etc/SuSE-release | cut -d ' ' -f 3).
INITSCRIPT=suse.init.script
endif

# No hyphens are allowed in the _version field in RPM
PKG_VERSION_NO_H	?= $(shell echo $(PKG_VERSION) | tr - .)

default: init.script
	mkdir -p BUILD
	mkdir -p packages
	echo "** RAWR **"
	rpmbuild --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}$(DISTRO)%%{ARCH}.rpm" \
		--define '_topdir $(PWD)' \
		--define '_sourcedir $(PWD)' \
		--define '_specdir $(PWD)' \
		--define '_rpmdir $(PWD)/packages' \
		--define '_srcrpmdir $(PWD)/packages' \
		--define "_revision $(PKG_VERSION)" \
		--define "_version $(PKG_VERSION_NO_H)" \
		--define "_release $(PKG_BUILD)" \
		--define "_tarname $(PKG_ID).tar.gz" \
		--define "_tarname_base $(PKG_ID)" \
		-ba $(PWD)/specfile
	cd packages && \
		for rpmfile in *.rpm; do \
			sha256sum $${rpmfile} > $${rpmfile}.sha \
		; done

init.script:
	cp $(INITSCRIPT) init.script
