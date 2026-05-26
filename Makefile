PREFIX ?= /usr/local
HOMEBREW_SKEL_DIR ?= $(HOME)/Dev/homebrew-skel

install:
	install -m 755 skel.sh $(DESTDIR)$(PREFIX)/bin/skel

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/skel

test:
	bash test.sh

release:
	@version=$$(grep '^VERSION=' skel.sh | cut -d'"' -f2); \
	echo "Releasing v$$version..."; \
	echo ""; \
	echo "Step 1: tag and push"; \
	git tag "v$$version" && git push && git push origin "v$$version"; \
	echo ""; \
	echo "Step 2: computing sha256 (fetching tarball)..."; \
	sha=$$(curl -sL "https://github.com/mark-mcdermott/skel/archive/refs/tags/v$$version.tar.gz" | shasum -a 256 | cut -d' ' -f1); \
	echo "sha256: $$sha"; \
	echo ""; \
	echo "Step 3: updating homebrew-skel formula..."; \
	formula="$(HOMEBREW_SKEL_DIR)/Formula/skel.rb"; \
	sed -i '' "s|url \".*\"|url \"https://github.com/mark-mcdermott/skel/archive/refs/tags/v$$version.tar.gz\"|" "$$formula"; \
	sed -i '' "s|sha256 \".*\"|sha256 \"$$sha\"|" "$$formula"; \
	echo "Updated $$formula"; \
	echo ""; \
	echo "Step 4: committing homebrew-skel..."; \
	git -C "$(HOMEBREW_SKEL_DIR)" add Formula/skel.rb; \
	git -C "$(HOMEBREW_SKEL_DIR)" commit -m "release: update formula for v$$version"; \
	git -C "$(HOMEBREW_SKEL_DIR)" push; \
	echo ""; \
	echo "Done. v$$version is live."

.PHONY: install uninstall test release
