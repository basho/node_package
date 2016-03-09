BUILDDIR        = $(shell pwd)
BUILD_STAGE_DIR = $(BUILDDIR)/{{package_name}}

# Where we install things (based on vars.config)
# /usr/local based dirs
PMAN_DIR         = $(BUILD_STAGE_DIR)/man
PBIN_DIR         = $(BUILD_STAGE_DIR)/{{bin_or_sbin}}
PETC_DIR         = $(BUILD_STAGE_DIR)/etc/{{package_install_name}}
PLIB_DIR         = $(BUILD_STAGE_DIR)/lib/{{package_install_name}}
# /var based dirs
PDATA_DIR        = $(BUILD_STAGE_DIR)/{{platform_data_dir}}
PLOG_DIR         = $(BUILD_STAGE_DIR)/log/{{package_install_name}}

# For scanning later, remove the leading slash
# '/var/db/server' becomes 'var/db/server'
PDATA_ROOT_DIR   = $(shell echo "{{platform_data_dir}}" | cut -d'/' -f 2-4)

TARNAME = {{package_name}}-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tar
PKGNAME = {{package_name}}-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tbz

build: packing_list_files templates
	@echo "Building package $(PKGNAME)"
	mkdir -p packages
	cd $(BUILD_STAGE_DIR) && \
	tar -cf $(TARNAME) +CONTENTS +COMMENT +DESC +MTREE_DIRS +DEINSTALL +DISPLAY
	cd $(BUILD_STAGE_DIR) && \
	find man -type f | tar -rf $(TARNAME) -T - && \
	find {{bin_or_sbin}} -type f | tar -rf $(TARNAME) -T - && \
	find lib -type f | tar -rf $(TARNAME) -T - && \
	find etc -type f | tar -rf $(TARNAME) -T - && \
	find var -type f | tar -rf $(TARNAME) -T - && \
	find log -type f | tar -rf $(TARNAME) -T -

	cd $(BUILD_STAGE_DIR) && \
	mkdir ../../packages && \
	gzip $(TARNAME) && \
	mv $(TARNAME).gz ../../packages/$(PKGNAME)

	cd ../packages && \
		for tarfile in *.tbz; do \
		shasum -a 256 $${tarfile} > $${tarfile}.sha \
	; done

# Where most of the magic (horror?) happens
# Create a packing list according to pkg_create(1)
# Write initial settings to a local file then copy
#   to the destination folder where we use 'find'
#   to populate the files and directories
# Regarding @owner and @group callouts
#   They work on files, but not on directories.
#   Also, the last callout should be blank to revert
#   back to the default so the /var/db/pkg directory
#   doesn't get set to something bad (which is a
#   horrible bug in pkg_add).
packing_list_files: $(BUILD_STAGE_DIR)
	@echo "Adding to packaging list {{package_name}}-$(PKG_VERSION)"
	echo "@name {{package_name}}-$(PKG_VERSION)" >> plist
	echo "@conflicts {{package_name}}-*" >> plist
	echo "@exec if ! pw groupshow {{package_install_group}} 2>/dev/null; then pw groupadd {{package_install_group}}; fi" >> plist
	echo "@exec if ! pw usershow {{package_install_user}} 2>/dev/null; then pw useradd {{package_install_user}} -g {{package_install_group}} -h - -d {{platform_data_dir}} -s /bin/sh -c \"{{package_install_user_desc}}\"; fi" >> plist
	echo "@comment ORIGIN:{{freebsd_package_category}}/{{package_install_name}}" >> plist

	@echo "Copying Man pages to staging directory"
	if [ -d doc/man/man1 ]; then \
		mkdir -p $(PMAN_DIR) && \
		cp -R doc/man/man1 $(PMAN_DIR) && \
		echo "@cwd /usr/local" >> plist  && \
		echo "@owner root" >> plist && \
		echo "@group wheel" >> plist && \
                {{#package_commands}}if [ -f doc/man/man1/{{name}}.1.gz ]; then \
                                         echo "man/man1/{{name}}.1.gz" >> plist \
                                     ; fi && \
		{{/package_commands}} echo -n; fi

	@echo "Scanning data and log directories for empty directories to add"
	$(eval PACKAGE_USER_WRITABLE_DIRS = {{platform_log_dir}})
	$(eval PACKAGE_USER_WRITABLE_DIRS += $(shell cd $(BUILD_STAGE_DIR) && find $(PDATA_ROOT_DIR) -type d -exec printf "/%s " {} \;))
	for i in $(PACKAGE_USER_WRITABLE_DIRS); \
	    do                          \
		echo "@exec mkdir -p $$i" >> plist; \
                echo "@exec chown -R {{package_install_user}}:{{package_install_group}} $$i" >> plist; \
		echo "@exec chmod 700 $$i" >> plist; \
	    done

	@echo "Copying staging package listing to +CONTENTS"
	mv plist $(BUILD_STAGE_DIR)/+CONTENTS

	@echo "Packaging /usr/local files"
	cd $(BUILD_STAGE_DIR) && \
	   echo "@cwd /usr/local" >> +CONTENTS && \
	   echo "@owner root" >> +CONTENTS && \
	   echo "@group wheel" >> +CONTENTS && \
	   echo "@mode 0755" >> +CONTENT
	cd $(BUILD_STAGE_DIR) && \
	   find lib -type f >> +CONTENTS && \
	   find lib -d -type d -mindepth 1 -exec echo "@dirrm {}" \; >> +CONTENTS && \
	   echo "@exec chown -R root:wheel {{platform_base_dir}}" >> +CONTENTS && \
	   find {{bin_or_sbin}} -type f >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   echo "@mode 0644" >> +CONTENTS && \
	   find etc -type f >> +CONTENTS && \
	   find etc -d -type d -mindepth 1 -exec echo "@dirrm {}" \; >> +CONTENTS
	@echo "Packaging /var files"
	cd $(BUILD_STAGE_DIR) && \
	   echo "@cwd /var" >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   echo "@owner {{package_install_user}}" >> +CONTENTS && \
	   echo "@group {{package_install_group}}" >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   find var/db -type f >> +CONTENTS
	cd $(BUILD_STAGE_DIR) && \
	   find log -type f >> +CONTENTS

	cd $(BUILD_STAGE_DIR) && \
	   echo "@owner" >> +CONTENTS && \
	   echo "@group" >> +CONTENTS && \
	   echo "@mode"  >> +CONTENTS && \
	   echo "@display +DISPLAY" >> +CONTENTS


templates: $(BUILD_STAGE_DIR)
	@echo "Copying metadata files to package"
	cp $(PKGERDIR)/+DESC $(PKGERDIR)/+COMMENT $(PKGERDIR)/+DEINSTALL \
           $(PKGERDIR)/+MTREE_DIRS $(PKGERDIR)/+DISPLAY \
           $(BUILD_STAGE_DIR)


# Copy the app rel directory to the staging directory to build our
# package structure and move the directories into the right place
# for the package, see the vars.config file for destination
# directories
$(BUILD_STAGE_DIR): buildrel
	@echo "Copying rel directory to staging directory"
	mkdir -p $@
	mkdir -p $(PBIN_DIR)
	cp -R rel/{{package_install_name}}/bin/* $(PBIN_DIR)
	mkdir -p $(PETC_DIR)
	cp -R rel/{{package_install_name}}/etc/* $(PETC_DIR)
	mkdir -p $(PLIB_DIR)
	cp -R rel/{{package_install_name}}/lib $(PLIB_DIR)
	cp -R rel/{{package_install_name}}/erts-* $(PLIB_DIR)
	cp -R rel/{{package_install_name}}/releases $(PLIB_DIR)
	mkdir -p $(PDATA_DIR)
	cp -R rel/{{package_install_name}}/data/* $(PDATA_DIR)
	mkdir -p $(PLOG_DIR)


# Build the release we need to package
#  * Ensure all binaries are executable
#  * copy the vars.config over for build config
buildrel:
	OVERLAY_VARS="overlay_vars=../fbsd/vars.config" $(MAKE) rel
	chmod 0755 rel/{{package_install_name}}/bin/* rel/{{package_install_name}}/erts-*/bin/*

$(BUILDDIR):
	mkdir -p $@

$(PKGERDIR)/pkgclean:
	rm -rf $(BUILD_STAGE_DIR) $(BUILDDIR)
