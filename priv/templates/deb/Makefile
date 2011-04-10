
default:
	echo "$(TAG) $(REVISION)"
	export DEBFULLNAME="Basho Buildbot Packager"; \
	export DEBEMAIL="support@basho.com"; \
	dch  --create --package {{package_name}} -v "$(REVISION)-$(RELEASE)" \
             "Build from $(REVISION)";\
	debuild --no-lintian \
                --prepend-path=$(ERLANG_BIN) \
		-e REVISION=$(REVISION) \
		-e RELEASE=$(RELEASE) \
                -e REBAR=$(REBAR) \
		-uc -us
