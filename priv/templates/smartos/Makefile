BUILDDIR        = $(shell pwd)
# SmartOS doesn't like package names with '-' in the name, so clean any if they
# exist
PACKAGE_NAME_CLEAN = $(shell echo "{{package_name}}" | sed -e 's/-/_/g')
BUILD_STAGE_DIR = $(BUILDDIR)/$(PACKAGE_NAME_CLEAN)

## Version Information
## ## pkgsrc version mapping to SmartOS version
##   SmartOS                 pkgsrc
##   1.6                     2011Q4
##   1.8                     2012Q2
##   13.1                    2013Q1
## ## Erlang Deps by version
##   SmartOS      openssl        ncurses
##   1.6          0.9.8knb1      5.4nb1
##   1.8          0.9.8knb1      5.4nb1
##  13.1          1.0.1c         5.4nb1
##
## ## SMF Manifest Mapping
##   SmartOS     Manifest File
##   1.6         manifest16.xml
##   1.8         manifest18.xml
##  13.1         manifest131.xml

PKGSRC_VERSION = $(shell head -1 /etc/pkgsrc_version 2>/dev/null | cut -d' ' -f2)

ifeq ($(PKGSRC_VERSION),2011Q4)  # SmartOS 1.6
NCURSES_DEP = ncurses-5*
OPENSSL_DEP = openssl-0.9.8*
GCC_DEP     = gcc-runtime-4.6.2
SMF_MANIFEST = manifest16.xml
endif
ifeq ($(PKGSRC_VERSION),2012Q2)  # SmartOS 1.8
NCURSES_DEP = ncurses-5*
OPENSSL_DEP = openssl-0.9.8*
GCC_DEP     = gcc47-runtime>=4.7.0
SMF_MANIFEST = manifest18.xml
endif
ifeq ($(PKGSRC_VERSION),2013Q1)  # SmartOS 13.1
NCURSES_DEP = ncurses-5*
OPENSSL_DEP = openssl-1.0.1*
GCC_DEP     = gcc47-libs>=4.7.0
SMF_MANIFEST = manifest131.xml
endif
ifeq ($(PKGSRC_VERSION),2015Q4)  # SmartOS 15.4.0
NCURSES_DEP = ncurses-6*
OPENSSL_DEP = openssl-1.0.2*
GCC_DEP     = gcc49-libs>=4.9.3
SMF_MANIFEST = manifest154.xml
endif


# Where we install things (based on vars.config)
# /opt/local based dirs
# /var based dirs are handled in the +INSTALL file and dirs_file target
PMAN_DIR         := $(BUILD_STAGE_DIR)/man
PBIN_DIR         := $(BUILD_STAGE_DIR)/{{bin_or_sbin}}
PETC_DIR         := $(BUILD_STAGE_DIR)/etc/{{package_install_name}}
PLIB_DIR         := $(BUILD_STAGE_DIR)/lib/{{package_install_name}}
PSMF_DIR         := $(BUILD_STAGE_DIR)/share/smf/{{package_install_name}}
ESMF_DIR         := $(BUILD_STAGE_DIR)/share/smf/{{package_install_name}}-epmd
PDATA_DIR        := $(BUILD_STAGE_DIR)/{{platform_data_dir}}

# For scanning later, grab the first dirname
# '/var/db/server' becomes 'var'
PDATA_ROOT_DIR   = $(shell echo "{{platform_data_dir}}" | cut -d'/' -f 2)



# Recursive assignment of ERTS version
# We will know this after building the rel
ERTS_PATH        = $(shell ls $(BUILDDIR)/rel/{{package_install_name}} | egrep -o "erts-.*")

TARNAME := $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tar
PKGNAME := $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tgz

# pkg_add on Smartos requires that the tar file
# and +CONTENTS files are in the exact same order
# so we need to pack up the tar in a very
# particular order to not anger pkg_add.
# This is done by piping the file listings into tar
#  in the same manner we did with the +CONTENTS file
build: packing_list_files dirs_file
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
		for tarfile in *.tgz; do \
		shasum -a 256 $${tarfile} > $${tarfile}.sha \
	; done


# Where most of the magic (horror?) happens
# Create a packing list according to pkg_create(1)
# Write initial settings to a local plist then copy
#   to the destination folder where we use 'find'
#   to populate the files
# SmartOS doesn't allow packages to modify /var
#   in the +CONTENTS so that is all done in the +INSTALL instead
packing_list_files: $(BUILD_STAGE_DIR) templates
	@echo "Adding to packaging list $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)"
	echo "@name $(PACKAGE_NAME_CLEAN)-$(PKG_VERSION)" >> plist
	echo "@pkgcfl $(PACKAGE_NAME_CLEAN)-*" >> plist
	echo "@pkgdep $(OPENSSL_DEP)" >> plist
	echo "@pkgdep $(NCURSES_DEP)" >> plist
	echo "@pkgdep $(GCC_DEP)" >> plist

	@echo "Copying staging package listing to +CONTENTS"
	mv plist $(BUILD_STAGE_DIR)/+CONTENTS

	@echo "Packaging /opt/local files"
	cd $(BUILD_STAGE_DIR) && \
	   echo "@comment Packing manpage files" >> +CONTENTS && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group root" >> +CONTENTS && \
	   find man -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@comment Packing /opt/local/etc files" >> +CONTENTS && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group {{package_install_user}}" >> +CONTENTS && \
	   find etc -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@comment Packing lib files" >> +CONTENTS && \
	   echo "@cwd /opt/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group root" >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   find lib -type f >> +CONTENTS && \
	   echo "@exec chown -R root:root {{platform_base_dir}}" >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@comment Packing /usr/local {{bin_or_sbin}} files" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group root" >> +CONTENTS && \
	   echo "@mode 0755" >> +CONTENTS && \
	   find {{bin_or_sbin}} -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group root" >> +CONTENTS && \
	   find share -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@display +DISPLAY" >> +CONTENTS


# Creates a variable to be read by the +INSTALL script to
# create directories not supported by the +CONTENTS file
# such as log and data directories.
# platform_log_dir and platform_data_dir are always added
# This is black magic appending the directories to
# a variable inside of the makefile target
# and then using sed to insert that list into
# the +INSTALL script.
# I feel dirty now.
dirs_file: $(BUILD_STAGE_DIR)
	@echo "Adding data and log directories to directory list"
	$(eval PACKAGE_USER_WRITABLE_DIRS = {{platform_data_dir}})
	$(eval PACKAGE_USER_WRITABLE_DIRS += {{platform_log_dir}})
	@echo "Scanning var directory for any additional install paths"
	$(eval PACKAGE_USER_WRITABLE_DIRS += $(shell cd $(BUILD_STAGE_DIR) && find $(PDATA_ROOT_DIR) -type d -exec printf "/%s " {} \;))
	cd $(BUILD_STAGE_DIR) && \
	   cp +INSTALL +INSTALL.tmp && \
	   sed -e 's|%PACKAGE_USER_WRITABLE_DIRS%|${PACKAGE_USER_WRITABLE_DIRS}|' < \
	       +INSTALL.tmp > +INSTALL && \
	   rm +INSTALL.tmp


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
# We copy the data and log directories if they exist to make
# scanning them easier later
$(BUILD_STAGE_DIR): buildrel patch_runner
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
	@echo "Copying man pages to staging directory"
	mkdir -p $(PMAN_DIR)
	if [ -d $(BUILDDIR)/doc/man/man1 ]; then \
	    cp -R $(BUILDDIR)/doc/man/man1 $(PMAN_DIR); fi
	@echo "Copying data and log directories to staging directory"
	if [ -d $(BUILDDIR)/rel/{{package_install_name}}/data ]; then \
	   mkdir -p $(PDATA_DIR) && \
	   cp -R $(BUILDDIR)/rel/{{package_install_name}}/data/* $(PDATA_DIR); fi


# If we can read the PKGSRC_VERSION we should fail
# If NCURSES_DEP wasn't set, we know it was an unknown PKGSRC version
smartos_check:
	@echo "Checking SmartOS Version"
	$(if $(PKGSRC_VERSION),,$(error "Cannot find pkgsrc version from /etc/pkgsrc_version, cannot continue"))
	$(if $(NCURSES_DEP),,$(error "Unsupported SmartOS version, please add to github.com/basho/node_package"))
	@echo "Building for pkgsrc version $(PKGSRC_VERSION)"

# Patch the runner script with SmartOS modifications
patch_runner: buildrel
	cp $(PKGERDIR)/runner.patch $(BUILDDIR)/rel/{{package_install_name}}/bin/
	cd $(BUILDDIR)/rel/{{package_install_name}}/bin && \
	   patch -p0 {{package_install_name}} runner.patch
	rm $(BUILDDIR)/rel/{{package_install_name}}/bin/runner.patch


# Build the release we need to package
#  * Ensure all binaries are executable
#  * copy the vars.config over for build config
buildrel: $(BUILDDIR) smartos_check
	OVERLAY_VARS="overlay_vars=../smartos/vars.config" $(MAKE) rel
	chmod 0755 $(BUILDDIR)/rel/{{package_install_name}}/bin/* $(BUILDDIR)/rel/{{package_install_name}}/erts-*/bin/*

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
