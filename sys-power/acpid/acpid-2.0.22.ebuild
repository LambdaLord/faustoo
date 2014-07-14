# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-power/acpid/acpid-2.0.22.ebuild,v 1.1 2014/03/21 08:28:23 ssuominen Exp $

EAPI=5
inherit systemd

DESCRIPTION="Daemon for Advanced Configuration and Power Interface"
HOMEPAGE="http://sourceforge.net/projects/acpid2"
SRC_URI="mirror://sourceforge/${PN}2/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ia64 -ppc ~x86"
IUSE="gnome selinux"

RDEPEND="selinux? ( sec-policy/selinux-apm )
		 gnome? ( gnome-base/gnome-settings-daemon[deprecated] )"
DEPEND="${RDEPEND}
	    >=sys-kernel/linux-headers-3"

src_prepare() {
	if use gnome; then
		# From Funtoo:
		# 	https://bugs.funtoo.org/browse/FL-1329
		epatch "${FILESDIR}"/${P}-rename-gnome-power-management-system-process.patch
	fi
}

src_configure() {
	econf --docdir=/usr/share/doc/${PF}
}

src_install() {
	emake DESTDIR="${D}" install

	newdoc kacpimon/README README.kacpimon
	dodoc -r samples
	rm -f "${D}"/usr/share/doc/${PF}/COPYING || die

	exeinto /etc/acpi
	newexe "${FILESDIR}"/${PN}-1.0.6-default.sh default.sh
	exeinto /etc/acpi/actions
	newexe samples/powerbtn/powerbtn.sh powerbtn.sh
	insinto /etc/acpi/events
	newins "${FILESDIR}"/${PN}-1.0.4-default default

	newinitd "${FILESDIR}"/${PN}-2.0.16-init.d ${PN}
	newconfd "${FILESDIR}"/${PN}-2.0.16-conf.d ${PN}

	systemd_dounit "${FILESDIR}"/systemd/${PN}.{service,socket}
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog
		elog "You may wish to read the Gentoo Linux Power Management Guide,"
		elog "which can be found online at:"
		elog "http://www.gentoo.org/doc/en/power-management-guide.xml"
		elog
	fi

	# files/systemd/acpid.socket -> ListenStream=/run/acpid.socket
	mkdir -p "${ROOT%/}"/run

	if ! grep -qs "^tmpfs.*/run " "${ROOT%/}"/proc/mounts ; then
		echo
		ewarn "You should reboot the system now to get /run mounted with tmpfs!"
	fi
}