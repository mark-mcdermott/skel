PREFIX ?= /usr/local
HOMEBREW_SKEL_DIR ?= $(HOME)/Dev/homebrew-skel

# Vercel deploy hook for skel.sh. Deliberately empty here: the URL is a
# credential and this repo is public. Export it in your shell instead.
SKEL_SH_DEPLOY_HOOK ?=

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
	echo "Step 5: refreshing skel.sh..."; \
	$(MAKE) --no-print-directory deploy-site; \
	echo ""; \
	echo "Done. v$$version is live."

# Tells skel.sh to rebuild. The site reads the released version from this repo's
# git tags at build time, so without this it keeps showing whatever was current
# when it last deployed. Split out so a release that ran without the hook set
# can be fixed with `make deploy-site` rather than a re-release.
deploy-site:
	@if [ -z "$(SKEL_SH_DEPLOY_HOOK)" ]; then \
		echo "  SKEL_SH_DEPLOY_HOOK is not set — skel.sh was NOT refreshed and will"; \
		echo "  keep showing the previous version. Grab the URL from Vercel"; \
		echo "  (skel.sh > Settings > Git > Deploy Hooks), export it, then run:"; \
		echo "      make deploy-site"; \
		exit 0; \
	fi; \
	if curl -fsS -X POST "$(SKEL_SH_DEPLOY_HOOK)" >/dev/null; then \
		echo "  skel.sh rebuild triggered."; \
	else \
		echo "  Deploy hook failed. skel.sh still shows the previous version."; \
		echo "  Retry with: make deploy-site"; \
		exit 1; \
	fi

.PHONY: install uninstall test release deploy-site
