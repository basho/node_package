PKGNAME = {{package_name}}-$(PKG_VERSION)-$(OSNAME)-$(ARCH).tar.gz

default: buildrel
	mkdir -p packages
	mkdir -p osxbuild
	cd $(PKG_ID) && \
		cp -R rel/{{package_install_name}} \
		   ../osxbuild/{{package_name}}-$(PKG_VERSION)
	tar -czf packages/$(PKGNAME) \
		 osxbuild/{{package_name}}-$(PKG_VERSION)
	cd packages && \
	   for tarfile in `ls *.gz`; do \
	       shasum -a 256 $${tarfile} > $${tarfile}.sha \
	   ; done


buildrel: $(PKG_ID)
	cd $^ && \
		$(MAKE) deps compile rel
