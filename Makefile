PREFIX ?= /usr/local

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
	echo "Step 2: publish the GitHub Release"; \
	$(MAKE) --no-print-directory publish-release VERSION_TAG="v$$version"; \
	echo ""; \
	echo "Done. Publishing the Release is what does the rest, in GitHub Actions:"; \
	echo "  - bumps the Homebrew formula (homebrew-bump.yml)"; \
	echo "  - refreshes skel.sh (notify-site.yml)"; \
	echo ""; \
	echo "Watch them with:  gh run list --repo mark-mcdermott/skel"

# Publishing the Release is what refreshes skel.sh: the site's sync workflow
# keys off `release: published` via a repository_dispatch, and its sync script
# reads the latest *release* tag. A tag alone is not enough — it fires nothing
# and the site keeps showing the previous version.
#
# This replaced a Vercel deploy hook that only fired from the one machine
# holding SKEL_SH_DEPLOY_HOOK, so a release published any other way silently
# left the site stale.
publish-release:
	@if ! command -v gh >/dev/null 2>&1; then \
		echo "  gh is not installed — the Release was NOT published and skel.sh will"; \
		echo "  keep showing the previous version. Install gh, then run:"; \
		echo "      make publish-release VERSION_TAG=$(VERSION_TAG)"; \
		exit 1; \
	fi; \
	if gh release view "$(VERSION_TAG)" >/dev/null 2>&1; then \
		echo "  Release $(VERSION_TAG) already exists; nothing to publish."; \
	elif gh release create "$(VERSION_TAG)" --title "$(VERSION_TAG)" --generate-notes; then \
		echo "  Release published. skel.sh will re-sync within a minute."; \
	else \
		echo "  Publishing failed. skel.sh still shows the previous version."; \
		echo "  Retry with: make publish-release VERSION_TAG=$(VERSION_TAG)"; \
		exit 1; \
	fi

.PHONY: install uninstall test release publish-release
