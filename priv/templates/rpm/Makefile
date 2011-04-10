
PWD    = $(shell pwd)
DISTRO = $(shell head -1 /etc/redhat-release| awk \
           '{if ($$0 ~ /CentOS/) { print ".el5."} else { print "." }} ')
RPM_VERSION = $(shell echo $(REVISION) | tr - .)

default:
	@echo "DISTRO   = $(DISTRO)"
	@echo "RIAK_TAG = $(RIAK_TAG)"
	@echo "REVISION = $(REVISION)"
	@echo "RELEASE  = $(RELEASE)"
	mkdir -p BUILD
	rpmbuild --define "_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}$(DISTRO)%%{ARCH}.rpm" \
		 --define '_topdir $(PWD)' \
		 --define '_sourcedir $(PWD)' \
		 --define '_specdir $(PWD)' \
		 --define '_rpmdir $(PWD)' \
		 --define '_srcrpmdir $(PWD)' \
		 --define "_revision $(REVISION)" \
		 --define "_version $(RPM_VERSION)" \
		 --define "_release $(RELEASE)" \
		 -ba $(PWD)/specfile

