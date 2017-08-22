# Name of your emacs binary
EMACS = emacs

# Where local software is found
prefix = /usr/share

# Where local lisp files go
lispdir = $(prefix)/emacs/site-lisp/eno

# Where local data files go
datadir = $(prefix)/emacs/etc/eno

# Where info files go.
infodir = $(prefix)/info

# Start Emacs  with no user and site configuration
EMACSQ = $(EMACS) -Q

# Using Emacs in batch mode
BATCH = $(EMACSQ) -batch \
	--eval '(setq vc-handled-backends nil org-startup-folded nil)'

# Emacs must be started in lisp directory
BATCHL = $(BATCH) \
	 --eval '(add-to-list '"'"'load-path ".")'

# How to generate eno-loaddefs.el
MAKE_ENO_INSTALL = $(BATCHL) \
	  --eval '(load "org-compat.el")' \
	  --eval '(load "../mk/eno-fixup.el")' \
	  --eval '(eno-make-eno-loaddefs)'

# How to generate org-version.el
MAKE_ENO_VERSION = $(BATCHL) \
	  --eval '(load "org-compat.el")' \
	  --eval '(load "../mk/eno-fixup.el")' \
	  --eval '(eno-make-eno-version "$(ENOVERSION)" "$(GITVERSION)" "'$(datadir)'")'

# How to byte-compile the whole source directory
ELCDIR = $(BATCHL) \
	 --eval '(batch-byte-recompile-directory 0)'

# How to byte-compile a single file
ELC = $(BATCHL) \
      --eval '(batch-byte-compile)'

# How to create directories with leading path components
MKDIR = install -m 755 -d

# How to remove files
RM = rm -f

# How to copy the lisp files and elc files to their destination.
CP = install -m 644 -p

# target method for 'compile'
ORGCM = dirall
