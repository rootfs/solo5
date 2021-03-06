# Copyright (c) 2015, IBM
# Author(s): Dan Williams <djwillia@us.ibm.com>
#
# Permission to use, copy, modify, and/or distribute this software for
# any purpose with or without fee is hereby granted, provided that the
# above copyright notice and this permission notice appear in all
# copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE
# AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
# DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA
# OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER
# TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.

export TOP=$(abspath .)
$(TOP)/Makeconf:
	./configure.sh
include Makefile.common

.PHONY: all
all: ukvm virtio
.DEFAULT_GOAL := all

.PHONY: virtio
virtio:
ifeq ($(BUILD_VIRTIO), yes)
	$(MAKE) -C kernel virtio
	$(MAKE) -C tests virtio
endif

.PHONY: ukvm
ukvm:
ifeq ($(BUILD_UKVM), yes)
	$(MAKE) -C kernel ukvm
	$(MAKE) -C tests ukvm
endif

.PHONY: clean
clean:
	$(MAKE) -C kernel clean
	$(MAKE) -C tests clean
	$(RM) solo5-kernel-virtio.pc
	$(RM) solo5-kernel-ukvm.pc
	$(RM) -r include-host/
	$(RM) Makeconf

PREFIX?=/nonexistent # Fail if not run from OPAM
OPAM_BINDIR=$(PREFIX)/bin
OPAM_UKVM_LIBDIR=$(PREFIX)/lib/solo5-kernel-ukvm
OPAM_UKVM_INCDIR=$(PREFIX)/include/solo5-kernel-ukvm/include
OPAM_VIRTIO_LIBDIR=$(PREFIX)/lib/solo5-kernel-virtio
OPAM_VIRTIO_INCDIR=$(PREFIX)/include/solo5-kernel-virtio/include

# We want the MD CFLAGS and LDFLAGS in the .pc file, where they can be
# picked up by the Mirage tool / other downstream consumers.
%.pc: %.pc.in
	sed <$< > $@ \
	    -e 's#!CFLAGS!#$(MD_CFLAGS)#g;' \
	    -e 's#!LD!#$(LD)#g;' \
	    -e 's#!LDFLAGS!#$(LDFLAGS)#g;'

.PHONY: opam-virtio-install
opam-virtio-install: solo5-kernel-virtio.pc virtio
	mkdir -p $(OPAM_VIRTIO_INCDIR) $(OPAM_VIRTIO_LIBDIR)
	cp kernel/solo5.h $(OPAM_VIRTIO_INCDIR)/solo5.h
	mkdir -p $(OPAM_VIRTIO_INCDIR)/host
	cp -R include-host/. $(OPAM_VIRTIO_INCDIR)/host
	cp iso/boot/grub/menu.lst $(OPAM_VIRTIO_LIBDIR)
	cp iso/boot/grub/stage2_eltorito $(OPAM_VIRTIO_LIBDIR)
	cp kernel/virtio/solo5.o kernel/virtio/solo5.lds $(OPAM_VIRTIO_LIBDIR)
	mkdir -p $(OPAM_BINDIR)
	mkdir -p $(PREFIX)/lib/pkgconfig
	cp solo5-kernel-virtio.pc $(PREFIX)/lib/pkgconfig
	cp solo5-build-iso.bash $(OPAM_BINDIR)

.PHONY: opam-virtio-uninstall
opam-virtio-uninstall:
	rm -rf $(OPAM_VIRTIO_INCDIR) $(OPAM_VIRTIO_LIBDIR)
	rm -f $(PREFIX)/lib/pkgconfig/solo5-kernel-virtio.pc
	rm -f $(OPAM_BINDIR)/solo5-build-iso.bash

.PHONY: opam-ukvm-install
opam-ukvm-install: solo5-kernel-ukvm.pc ukvm
	mkdir -p $(OPAM_UKVM_INCDIR) $(OPAM_UKVM_LIBDIR)
	cp kernel/solo5.h $(OPAM_UKVM_INCDIR)/solo5.h
	cp ukvm/ukvm.h $(OPAM_UKVM_INCDIR)/ukvm.h
	mkdir -p $(OPAM_UKVM_INCDIR)/host
	cp -R include-host/. $(OPAM_UKVM_INCDIR)/host
	cp kernel/ukvm/solo5.o kernel/ukvm/solo5.lds $(OPAM_UKVM_LIBDIR)
	mkdir -p $(OPAM_BINDIR)
	mkdir -p $(OPAM_UKVM_LIBDIR)/src
	cp -R ukvm $(OPAM_UKVM_LIBDIR)/src
	cp ukvm/ukvm-configure $(OPAM_BINDIR)
	mkdir -p $(PREFIX)/lib/pkgconfig
	cp solo5-kernel-ukvm.pc $(PREFIX)/lib/pkgconfig

.PHONY: opam-ukvm-uninstall
opam-ukvm-uninstall:
	rm -rf $(OPAM_UKVM_INCDIR) $(OPAM_UKVM_LIBDIR)
	rm -f $(OPAM_BINDIR)/ukvm
	rm -f $(PREFIX)/lib/pkgconfig/solo5-kernel-ukvm.pc
