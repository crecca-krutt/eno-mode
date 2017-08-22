.EXPORT_ALL_VARIABLES:
.NOTPARALLEL: .PHONY

LISPDIRS = lisp
INSTSUB = $(LISPDIRS:%=install-%)

ifneq ($(wildcard .git),)
  GITVERSION ?= $(shell git describe --match release\* --abbrev=6 HEAD)
  ENOVERSION ?= $(subst release_,,$(shell git describe --match release\* --abrev=0 HEAD))
  GITSTATUS ?= $(shell git status -uno --porcelain)
else
 -include mk/version.mk
  GITVERSION ?= N/A
  ENOVERSION ?= 0.0.1
endif
DATE = $(shell date +%Y-%m-%d)
YEAR = $(shell date +%Y)
ifneq ($(GITSTATUS),)
  GITVERSION := $(GITVERSION:.dirty=).dirty
endif

.PHONY: all $(LISPDIRS) install $(INSTSUB) autoloads clean cleanlisp compile

all compile::
	$(foreach dir, lisp, $(MAKE) -C $(dir) clean;)
compile::
	$(MAKE) -C lisp $@
all::
	$(foreach dir, lisp, $(MAKE) -C $(dir) $@;)

install:	$(INSTSUB)

$(INSTSUB):
	$(MAKE) -C $(@:install-%=%) install

autoloads: lisp
	$(MAKE) -C $< $@

clean: cleanlisp

cleanlisp:
	$(MAKE) -C $(@:clean%=%) clean
