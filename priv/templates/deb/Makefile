
default:
	export DEBFULLNAME="{{vendor_contact_name}}"; \
	export DEBEMAIL="{{vendor_contact_email}}"; \
	dch  --create --package {{package_name}} -v "$(PKG_VERSION)-$(PKG_BUILD)" \
             "Build from $(PKG_VERSION)";\
	debuild --prepend-path=$(ERLANG_BIN) \
		-e REVISION=$(PKG_VERSION) \
		-e RELEASE=$(PKG_BUILD) \
                -e REBAR=$(REBAR) \
		-uc -us
