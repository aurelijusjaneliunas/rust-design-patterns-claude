CLAUDE_PLUGIN := rust-design-patterns-claude.plugin
CURSOR_MDC := rust-design-patterns-cursor.mdc
SOURCES := skills .claude-plugin README.md LICENSE

.PHONY: build build-claude build-cursor clean

build: build-claude build-cursor

build-claude:
	rm -f $(CLAUDE_PLUGIN)
	py scripts/build_plugin.py $(CLAUDE_PLUGIN) $(SOURCES)

build-cursor:
	py scripts/build_cursor_mdc.py $(CURSOR_MDC)

clean:
	rm -f $(CLAUDE_PLUGIN) $(CURSOR_MDC)
