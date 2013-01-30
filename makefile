#
# Copyright (C) 2011 Richard Cochran <richardcochran@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

KBUILD_OUTPUT ?= /lib/modules/$(shell uname -r)/build

FEAT_CFLAGS :=
ifneq ($(shell grep clock_adjtime /usr/include/bits/time.h),)
FEAT_CFLAGS += -D_GNU_SOURCE -DHAVE_CLOCK_ADJTIME
endif

DEBUG	=
CC	= $(CROSS_COMPILE)gcc
INC	= -I$(KBUILD_OUTPUT)/usr/include
VER     = -DVER=$(version)
CFLAGS	= -Wall $(VER) $(INC) $(DEBUG) $(FEAT_CFLAGS) $(EXTRA_CFLAGS)
LDLIBS	= -lm -lrt $(EXTRA_LDFLAGS)
PRG	= ptp4l pmc phc2sys hwstamp_ctl
OBJ	= bmc.o clock.o config.o fsm.o ptp4l.o mave.o msg.o phc.o pi.o port.o \
 print.o raw.o servo.o sk.o tlv.o tmtab.o transport.o udp.o udp6.o uds.o util.o \
 version.o

OBJECTS	= $(OBJ) hwstamp_ctl.o phc2sys.o pmc.o pmc_common.o sysoff.o
SRC	= $(OBJECTS:.o=.c)
DEPEND	= $(OBJECTS:.o=.d)
srcdir	:= $(dir $(lastword $(MAKEFILE_LIST)))
version := $(shell $(srcdir)/version.sh $(srcdir))
VPATH	= $(srcdir)

prefix	= /usr/local
sbindir	= $(prefix)/sbin
mandir	= $(prefix)/man
man8dir	= $(mandir)/man8

all: $(PRG)

ptp4l: $(OBJ)

pmc: msg.o pmc.o pmc_common.o print.o raw.o sk.o tlv.o transport.o udp.o \
 udp6.o uds.o util.o version.o

phc2sys: phc2sys.o pi.o servo.o sk.o sysoff.o print.o version.o

hwstamp_ctl: hwstamp_ctl.o version.o

version.o: .version version.sh $(filter-out version.d,$(DEPEND))

.version: force
	@echo $(version) > .version.new; \
	cmp -s .version .version.new || cp .version.new .version; \
	rm -f .version.new;

force:

install: $(PRG)
	mkdir -p $(sbindir) $(man8dir)
	install $(PRG) $(sbindir)
	install -p -m 644 -t $(man8dir) $(PRG:%=%.8)

clean:
	rm -f $(OBJECTS) $(DEPEND)

distclean: clean
	rm -f $(PRG)
	rm -f .version

# Implicit rule to generate a C source file's dependencies.
%.d: %.c
	@echo DEPEND $<; \
	rm -f $@; \
	$(CC) -MM $(CPPFLAGS) $(CFLAGS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

ifneq ($(MAKECMDGOALS), clean)
ifneq ($(MAKECMDGOALS), distclean)
-include $(DEPEND)
endif
endif

.PHONY: all force clean distclean
