BINARY = sidecar-fix
INSTALL_DIR = /usr/local/bin
PLIST = com.jin.sidecar-fix.plist
LAUNCH_AGENTS = $(HOME)/Library/LaunchAgents

.PHONY: build install uninstall

build:
	swiftc Sources/SidecarFix.swift -o $(BINARY) -O

install: build
	mkdir -p $(LAUNCH_AGENTS)
	cp -f $(BINARY) $(INSTALL_DIR)/$(BINARY)
	printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0">' \
		'<dict>' \
		'  <key>Label</key>' \
		'  <string>com.jin.sidecar-fix</string>' \
		'  <key>ProgramArguments</key>' \
		'  <array>' \
		'    <string>$(INSTALL_DIR)/$(BINARY)</string>' \
		'    <string>daemon</string>' \
		'  </array>' \
		'  <key>KeepAlive</key>' \
		'  <true/>' \
		'  <key>RunAtLoad</key>' \
		'  <true/>' \
		'</dict>' \
		'</plist>' > $(LAUNCH_AGENTS)/$(PLIST)
	-launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS)/$(PLIST)
	launchctl bootstrap gui/$$(id -u) $(LAUNCH_AGENTS)/$(PLIST)
	@echo "Installed. Now arrange Sidecar to your preferred position,"
	@echo "then run: sidecar-fix save"
	@echo ""
	@echo "launchd will keep 'sidecar-fix daemon' running in the background."

uninstall:
	-launchctl bootout gui/$$(id -u) $(LAUNCH_AGENTS)/$(PLIST)
	-rm -f $(LAUNCH_AGENTS)/$(PLIST)
	-rm -f $(INSTALL_DIR)/$(BINARY)
