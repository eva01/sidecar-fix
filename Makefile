BINARY = sidecar-fix
INSTALL_DIR = /usr/local/bin
PLIST = com.jin.sidecar-fix.plist
LAUNCH_AGENTS = $(HOME)/Library/LaunchAgents

.PHONY: build install uninstall

build:
	swiftc Sources/SidecarFix.swift -o $(BINARY) -O

install: build
	cp $(BINARY) $(INSTALL_DIR)/$(BINARY)
	cp $(PLIST) $(LAUNCH_AGENTS)/$(PLIST)
	launchctl load $(LAUNCH_AGENTS)/$(PLIST)
	@echo "Installed. Now arrange Sidecar to your preferred position,"
	@echo "then run: sidecar-fix save"
	@echo ""
	@echo "launchd will run 'sidecar-fix apply' automatically whenever"
	@echo "/Library/Preferences/com.apple.windowserver.displays.plist changes."

uninstall:
	-launchctl unload $(LAUNCH_AGENTS)/$(PLIST)
	-rm $(LAUNCH_AGENTS)/$(PLIST)
	-rm $(INSTALL_DIR)/$(BINARY)
