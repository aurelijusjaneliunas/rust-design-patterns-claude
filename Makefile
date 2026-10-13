PLUGIN := rust-design-patterns.plugin
SOURCES := skills .claude-plugin README.md LICENSE

.PHONY: build clean

build:
	rm -f $(PLUGIN)
	py scripts/build_plugin.py $(PLUGIN) $(SOURCES)

clean:
	rm -f $(PLUGIN)
