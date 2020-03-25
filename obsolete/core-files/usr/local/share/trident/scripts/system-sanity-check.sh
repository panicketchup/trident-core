#!/bin/sh
# ===================
# Quick script to perform a system sanity check and fix things as needed
#
# ===================

test -e /sbin/rc-update
use_openrc=$?
#Verify that config files are setup
# - sudoers
if [ ! -e "/usr/local/etc/sudoers" ] && [ -e "/usr/local/etc/sudoers.dist" ] ; then
  cp "/usr/local/etc/sudoers.dist" "/usr/local/etc/sudoers"
fi
# - cupsd.conf
if [ ! -e "/usr/local/etc/cups/cupsd.conf" ] && [ -e "/usr/local/etc/cups/cupsd.conf.sample" ] ; then
  ln -s "/usr/local/etc/cups/cupsd.conf.sample" "/usr/local/etc/cups/cupsd.conf"
fi
# - sysctl.conf
if [ ! -e "/etc/sysctl.conf" ] ; then
  #if this file is missing, then ALL sysctl config files get ignored. Make sure it exists.
  touch "/etc/sysctl.conf"
fi
# - pulseaudio default.pa
pkg info -e pulseaudio-module-sndio
if [ $? -eq 0 ] && [ ! -e "/usr/local/etc/pulse/default.pa" ] && [ -e "/usr/local/etc/pulse/default.pa.trident" ] ; then
  ln -s "/usr/local/etc/pulse/default.pa.trident" "/usr/local/etc/pulse/default.pa"
fi
# - fonts.conf
if [ ! -e "/usr/local/etc/fonts/fonts.conf" ] && [ -e "/usr/local/etc/fonts/fonts.conf.sample" ] ; then
  ln -s "/usr/local/etc/fonts/fonts.conf.sample" "/usr/local/etc/fonts/fonts.conf"
fi
# - Qt5 qconfig-modules.h include file (supposed to be auto-generated?)
#if [ ! -e "/usr/local/include/qt5/QtCore/qconfig-modules.h" ] && [ -e "/usr/local/include/qt5/QtCore/qconfig.h" ] ; then
#  touch "/usr/local/include/qt5/QtCore/qconfig-modules.h"
#fi

#Ensure that the openrc devd configs are loaded from ports as well
if [ ${use_openrc} -eq 0 ]  ; then
  grep -q "/usr/local/etc/devd-openrc" "/etc/devd.conf"
  if [ $? -ne 0 ] ; then
    sed -i '' 's|directory "/usr/local/etc/devd";|directory "/usr/local/etc/devd";\
	directory "/usr/local/etc/devd-openrc";|' "/etc/devd.conf"
  fi
fi

# Ensure that the icon cache for the "hicolor" theme does not exist
# That cache file will break the auto-detection of new icons per the XDG spec
if [ -e "/usr/local/share/icons/hicolor/icon-theme.cache" ] ; then
  rm "/usr/local/share/icons/hicolor/icon-theme.cache"
fi

#Ensure that the PCDM config file exists, or put the default one in place
if [ ! -e "/usr/local/etc/pcdm.conf" ] ; then
  cp "/usr/local/etc/pcdm.conf.trident" "/usr/local/etc/pcdm.conf"
  #It can contain sensitive info - only allow root to read it
  chmod 700 "/usr/local/etc/pcdm.conf"
fi

# Make sure dbus machine-id file exists
  # QT needs a valid dbus machine-id file even if dbus is not used/started
  if [ ! -e "/var/lib/dbus/machine-id" ] ; then
    /usr/local/bin/dbus-uuidgen --ensure
  fi

# Always update the default wallpaper symlink
ln -sf "/usr/local/share/wallpapers/trident/trident_blue_4K.png" "/usr/local/share/wallpapers/trident/default.png"

#Ensure that the /sbin/service utility exists
if [ ! -e "/sbin/service" ] ; then
  if [ -e "/usr/sbin/service" ] ; then
    ln -s "/usr/sbin/service" "/sbin/service"
  else
    echo "[WARNING] Could not find the service utility!"
  fi
fi

#Make the symlink from /dev/cd0 to /dev/cdrom if needed (many apps use cdrom by default)
if [ -e "/dev/cd0" ] && [ ! -e "/dev/cdrom" ] ; then
  ln -s /dev/cd0 /dev/cdrom
fi

#Ensure that the autofs device automount line is present in /etc/auto_master
grep -qE "(-automount)" "/etc/auto_master"
if [ $? -ne 0 ] ; then
  echo "/.autofs         -automount      -nosuid,noatime" >> "/etc/auto_master"
fi

# Ensure that the "ld" binary is symlinked to ld.lld as needed
if [ ! -e "/usr/bin/ld" ] && [ -e "/usr/bin/ld.lld" ] ; then
  ln -s "/usr/bin/ld.lld" "/usr/bin/ld"
fi
