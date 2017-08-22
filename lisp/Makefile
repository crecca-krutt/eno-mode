.NOTPARALLEL:	# always run this make serially
.SUFFIXES:	# we don't need default suffix rules
ifeq ($(MAKELEVEL), 0)
  $(error This make needs to be started as a sub-make from the toplevel directory.)
endif

LISPV := eno-version.el
LISPI := eno-loaddefs.el
LISPA := $(LISPV) $(LISPI)
LISPB := $(LISPA:%el=%elc)
LISPF := $(filter-out $(LISPA),$(sort $(wildcard *.el) $(_ORG_ADD_EL_)))
LISPC := $(filter-out $(LISPB) $(LISPN:%el=%elc),$(LISPF:%el=%elc))
-include local.mk

.PHONY: all compile install clean cleanauto	

# do not clean here, done in toplevel make
all compile::	autoloads
	$(MAKE) compile-$(ORGCM)

compile-dirall: dirall

# internal
dirall:
	@$(info ==================== $@ ====================)
	@$(ELCDIR)

autoloads:	cleanauto $(LISPI) $(LISPV)

$(LISPV):	$(LISPF)
	@echo "eno-version: $(ENOVERSION) ($(GITVERSION))"
	@$(RM) $(@)
	@$(MAKE_ENO_VERSION)

$(LISPI):	$(LISPV) $(LISPF)
	@echo "eno-loaddefs: $(ENOVERSION) ($(GITVERSION))"
	@$(RM) $(@)
	@$(MAKE_ENO_INSTALL)

install:	compile $(LISPF)
	if [ ! -d $(DESTDIR)$(lispdir) ] ; then \
	  $(MKDIR) $(DESTDIR)$(lispdir) ; \
	fi ;
	$(CP) $(LISPC) $(LISPF) $(LISPA) $(DESTDIR)$(lispdir)

cleanauto clean::
	$(RM) $(LISPA) $(LISPB)
clean cleanall::
	$(RM) *.elc
