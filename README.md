# Pandoc local resources

Manual GitHub checkout at `~/.local/share/pandoc` on client machines. The
upstream executable remains independently installed; `~/.local/bin/pandoc`
uses the existing system executable. This repository is now independent of
`pandoc-server`, with no automatic synchronization.

Recovered reusable Lua filters retain their existing paths. Lua resources are
selected explicitly; their presence is not a claim that every historical filter
is supported. Transport/schema emitters, Redis/Git adapters, publishing layouts,
historical variants and known broken filters are excluded. The complete original
collection and provenance remain in the verified Tools archive and Dropbox ZIP.

Run `python3 tests/smoke.py` for the normalization defaults fixture. Other filters
need a relevant fixture before use. No Markdown writer is used for writeback;
raw frontmatter and slug validation remain owned by the unchanged clients.
