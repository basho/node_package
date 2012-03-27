
PWD    = $(shell pwd)
DISTRO = $(shell head -1 /etc/redhat-release| awk \
           '{if ($$0 ~ /CentOS release 5/) { print ".el5."} else { print "." }} ')

default:
	mkdir -p BUILD
	mkdir -p packages
	rpmbuild --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}$(DISTRO)%%{ARCH}.rpm" \
		 --define '_topdir $(PWD)' \
		 --define '_sourcedir $(PWD)' \
		 --define '_specdir $(PWD)' \
		 --define '_rpmdir $(PWD)/packages' \
		 --define '_srcrpmdir $(PWD)' \
		 --define "_revision $(PKG_VERSION)" \
		 --define "_version $(PKG_VERSION)" \
		 --define "_release $(PKG_BUILD)" \
		 -ba $(PWD)/specfile

