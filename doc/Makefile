.PHONY: all html clean

ASCIIDOC = asciidoc
ASCIIDOC_ARGS = --theme volnitsky

PAGES_ASC = index.asc
PAGES_ASC += install.asc
PAGES_ASC += usage.asc

PAGES_HTML = $(patsubst %.asc,%.html,$(PAGES_ASC))

all: html

%.html: %.txt
	$(ASCIIDOC) $(ASCIIDOC_ARGS) -b xhtml11 $<

html: $(PAGES_HTML)

clean:
	rm -f *.html
