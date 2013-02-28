BUILDDIR        = $(shell pwd)
# SmartOS doesn't like package names with '-' in the name, so clean any if they
# exist
PACKAGE_NAME_CLEAN = $(shell echo "{{package_name}}" | sed -e 's/-/_/g')
BUILD_STAGE_DIR = $(BUILDDIR)/$(PACKAGE_NAME_CLEAN)


# SmartOS changed pkgsrc versions which majorly changed
# the layout of the filesystem.  SmartOS 1.6 uses a
# different SMF manifest file than newer versions
SMF_MANIFEST = $(shell head -1 /etc/pkgsrc_version | \
                 grep -c 2011Q4 2> /dev/null | awk \
                 '{if ($$1 == "1") {print "manifest.xml"} else {print "manifest18.xml"}}')

# Where we install things (based on vars.config)
# /opt/local based dirs
PMAN_DIR         := $(BUILD_STAGE_DIR)/man
PBIN_DIR         := $(BUILD_STAGE_DIR)/{{bin_or_sbin}}
PETC_DIR         := $(BUILD_STAGE_DIR)/etc/{{package_install_name}}
PLIB_DIR         := $(BUILD_STAGE_DIR)/lib/{{package_install_name}}
PSMF_DIR         := $(BUILD_STAGE_DIR)/share/smf/{{package_install_name}}
ESMF_DIR         := $(BUILD_STAGE_DIR)/share/smf/{{package_install_name}}-epmd

# Recursive assignment of ERTS version
# We will know this after building the rel
ERTS_PATH        = $(shell ls $(BUILDDIR)/rel/{{package_install_name}} | egrep -o "erts-.*")

# /var based dirs are handled in the +INSTALL file

TARNAME := $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tar
PKGNAME := $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tgz

# pkg_add on Smartos requires that the tar file
# and +CONTENTS files are in the exact same order
# so we need to pack up the tar in a very
# particular order to not anger pkg_add.
# This is done by piping the file listings into tar
#  in the same manner we did with the +CONTENTS file
build: packing_list_files
	@echo "Building package $(PKGNAME)"
	mkdir -p packages
	cd $(BUILD_STAGE_DIR) && \
	tar -cf $(TARNAME) +CONTENTS +COMMENT +DESC +INSTALL +DEINSTALL +DISPLAY +BUILD_INFO
	cd $(BUILD_STAGE_DIR) && \
	find man -type f | tar -rf $(TARNAME) -T - && \
	find etc -type f | tar -rf $(TARNAME) -T - && \
	find lib -type f | tar -rf $(TARNAME) -T - && \
	find {{bin_or_sbin}} -type f | tar -rf $(TARNAME) -T - && \
	find share -type f | tar -rf $(TARNAME) -T -

	cd $(BUILD_STAGE_DIR) && \
	mkdir ../../packages && \
	gzip $(TARNAME) && \
	mv $(TARNAME).gz ../../packages/$(PKGNAME)

	cd ../packages && \
		for tarfile in `ls *.tgz`; do \
		shasum -a 256 $${tarfile} > $${tarfile}.sha \
	; done

# Where most of the magic (horror?) happens
# Create a packing list according to pkg_create(1)
# Write initial settings to a local plist then copy
#   to the destination folder where we use 'find'
#   to populate the files
packing_list_files: $(BUILD_STAGE_DIR) templates
	@echo "Adding to packaging list $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)"
	echo "@name $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)" >> plist
	echo "@pkgcfl $(PACKAGE_NAME_CLEAN)-*" >> plist
	echo "@pkgdep sudo-[0-9]*" >> plist
	echo "@pkgdep openssl-0.9.8*" >> plist

	@echo "Copying staging package listing to +CONTENTS"
	mv plist $(BUILD_STAGE_DIR)/+CONTENTS

	@echo "Packaging /opt/local files"
	cd $(BUILD_STAGE_DIR) && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group root" >> +CONTENTS && \
	   find man -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group {{package_install_user}}" >> +CONTENTS && \
	   find etc -type f >> +CONTENTS && \
	   echo "@exec chmod o-r {{platform_etc_dir}}/vm.args" >> +CONTENTS && \
	   echo "@exec chown -R root:{{package_install_group}} {{platform_etc_dir}}" >> +CONTENTS && \
	   echo "@exec chmod -R g+r+X {{platform_etc_dir}}" >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner {{package_install_user}}" >> +CONTENTS && \
	   echo "@group {{package_install_group}}" >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   find lib -type f >> +CONTENTS && \
	   echo "@exec chown -R {{package_install_user}}:{{package_install_group}} {{platform_base_dir}}" >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   echo "@owner {{package_install_user}}" >> +CONTENTS && \
	   echo "@group {{package_install_group}}" >> +CONTENTS && \
	   echo "@mode 0755" >> +CONTENTS && \
	   find {{bin_or_sbin}} -type f >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   echo "@owner {{package_install_user}}" >> +CONTENTS && \
	   echo "@group {{package_install_group}}" >> +CONTENTS && \
	   find share -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@display +DISPLAY" >> +CONTENTS


# These are static files that should not have to change often
templates: $(BUILD_STAGE_DIR)
	@echo "Copying metadata files to package"
	cp $(PKGERDIR)/+DESC $(PKGERDIR)/+COMMENT $(PKGERDIR)/+DEINSTALL \
           $(PKGERDIR)/+INSTALL $(PKGERDIR)/+BUILD_INFO \
	   $(PKGERDIR)/+DISPLAY $(BUILD_STAGE_DIR)
	mkdir -p $(PSMF_DIR)
	cp $(PKGERDIR)/$(SMF_MANIFEST) $(PSMF_DIR)/manifest.xml
	mkdir -p $(ESMF_DIR)
	sed -e "s/%ERTS_PATH%/${ERTS_PATH}/" < \
		$(PKGERDIR)/epmd > $(ESMF_DIR)/{{package_install_name}}-epmd
	cp $(PKGERDIR)/epmd-manifest.xml $(ESMF_DIR)/manifest.xml


# Copy the app rel directory to the staging directory to build our
# package structure and move the directories into the right place
# for the package, see the vars.config file for destination
# directories
# The data and log directories need to go into /var, but the
# smartos pkg_add doesn't allow this to be in the +CONTENTS
# file so the directories are created in the +INSTALL script
$(BUILD_STAGE_DIR): buildrel
	@echo "Copying rel directory to staging directory"
	mkdir -p $@
	cp -R $(BUILDDIR)/rel/{{package_install_name}} $(BUILD_STAGE_DIR)
	mkdir -p $(PBIN_DIR)
	cp -R $(BUILDDIR)/rel/{{package_install_name}}/bin/* $(PBIN_DIR)
	mkdir -p $(PETC_DIR)
	cp -R $(BUILDDIR)/rel/{{package_install_name}}/etc/* $(PETC_DIR)
	mkdir -p $(PLIB_DIR)
	cp -R $(BUILDDIR)/rel/{{package_install_name}}/lib $(PLIB_DIR)
	cp -R $(BUILDDIR)/rel/{{package_install_name}}/erts-* $(PLIB_DIR)
	cp -R $(BUILDDIR)/rel/{{package_install_name}}/releases $(PLIB_DIR)
	echo "Copying man pages to staging directory"
	mkdir -p $(PMAN_DIR)
	if [ -d $(BUILDDIR)/doc/man/man1 ]; then \
		cp -R $(BUILDDIR)/doc/man/man1 $(PMAN_DIR); fi



# Build the release we need to package
#  * Patch rel/files/riak with our version
#  * Ensure all binaries are executable
#  * copy the vars.config over for build config
# TODO, solve the .patch issue we have in riak
buildrel: $(BUILDDIR)
	OVERLAY_VARS="overlay_vars=../smartos/vars.config" $(MAKE) deps rel
	chmod 0755 $(BUILDDIR)/rel/{{package_install_name}}/bin/* $(BUILDDIR)/rel/{{package_install_name}}/erts-*/bin/*

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
