PREFIX   ?= /usr/local
SHAREDIR := $(PREFIX)/share/buildbox
BINDIR   := $(PREFIX)/bin
DOCDIR   := $(PREFIX)/share/doc/buildbox

.PHONY: all install install-core install-docker install-doc uninstall doc

all: doc

# --- Core install: library, commands, settings, host launcher ---

install: install-core install-docker

install-core:
	# API library
	install -d $(SHAREDIR)/lib
	install -m 644 src/_*.sh src/buildbox_utils.sh src/_pre_cmd $(SHAREDIR)/lib/

	# Commands (skip symlinks; re-create explicitly below)
	install -d $(SHAREDIR)/commands
	for cmd in src/commands/*; do \
	    [ -L "$$cmd" ] && continue; \
	    install -m 755 "$$cmd" "$(SHAREDIR)/commands/"; \
	done
	ln -sf build $(SHAREDIR)/commands/fastbuild

	# Patch container-side bbx: activate installed layout
	sed -i 's|^_BB_SHARE=.*|_BB_SHARE="$(SHAREDIR)"|' $(SHAREDIR)/commands/bbx

	# Settings
	install -d $(SHAREDIR)/settings/zsh/comp
	install -m 644 settings/zsh/.zshrc $(SHAREDIR)/settings/zsh/
	install -m 644 settings/zsh/comp/_* $(SHAREDIR)/settings/zsh/comp/

	# Shell prompt plugin + ZSH host-side completion
	install -d $(SHAREDIR)/shell
	install -m 644 settings/shell/bbx-prompt.sh $(SHAREDIR)/shell/
	install -m 644 settings/shell/bbx-completion.zsh $(SHAREDIR)/shell/
	install -m 644 settings/shell/bbx-completion.bash $(SHAREDIR)/shell/
	@echo ""
	@echo "To enable the BuildBox shell prompt, add this line to your ~/.bashrc or ~/.zshrc:"
	@echo "  source $(SHAREDIR)/shell/bbx-prompt.sh"
	@echo ""

	# Host launcher
	install -d $(BINDIR)
	install -m 755 docker/bin/bbx $(BINDIR)/bbx
	sed -i 's|^_BBX_SHARE=.*|_BBX_SHARE="$(SHAREDIR)"|' $(BINDIR)/bbx

# --- Docker build files ---

install-docker:
	install -d $(SHAREDIR)/docker/bin
	install -m 644 docker/99-custom-ttyUSB-permissions.rules $(SHAREDIR)/docker/
	install -m 755 docker/entrypoint.sh $(SHAREDIR)/docker/
	install -m 755 docker/bin/buildbox_tty_usb_sync $(SHAREDIR)/docker/bin/

# --- Documentation ---

doc:
	cd docs && npm run build

install-doc: doc
	install -d $(DOCDIR)
	cp -r docs/src/.vuepress/dist/. $(DOCDIR)/

# --- Uninstall ---

uninstall:
	rm -f $(BINDIR)/bbx
	rm -rf $(SHAREDIR)
	rm -rf $(DOCDIR)
