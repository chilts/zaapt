deb:
        fakeroot dpkg-buildpackage -b -tc -us -uc

check:
        lintian ../*.deb

all: deb check

.PHONY: all
