# Makefile - for the eno-mode distribution
# GNU make may be required
#
# None of this is part of GNU Emacs

# set up environment
 include mk/default.mk	# defaults, customizable via "local.mk"
-include local.mk	# optional local customization, use "default.mk" as template

# default target is "all"
all::

# Installation process is straightforward. Issue `make all' to compile
# and `make install' to install. You might need root to perform
# installation. `make clean' to remove compiled files.

 include mk/targets.mk	# toplevel make machinery
