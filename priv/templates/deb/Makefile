
default:
	export DEBFULLNAME="Basho Buildbot Packager"; \
	export DEBEMAIL="support@basho.com"; \
	dch  --create --package {{package_name}} -v "$(PKG_VERSION)-$(PKG_BUILD)" \
             "Build from $(PKG_VERSION)";\
	debuild --no-lintian \
                --prepend-path=$(ERLANG_BIN) \
		-e REVISION=$(PKG_VERSION) \
		-e RELEASE=$(PKG_BUILD) \
                -e REBAR=$(REBAR) \
		-uc -us
