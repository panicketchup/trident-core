#!/bin/sh
#Quick script to probe and re-generate the list of fonts that Xorg can use
#  based on what is installed on the system

_conf="/usr/local/etc/X11/xorg.conf.d/trident-xorg-files.conf"

_tmp="Section \"Files\"
  ModulePath    \"/usr/local/lib/xorg/modules\""

#Now probe for installed fonts and add them to the list
for _fontdir in `ls /usr/local/share/fonts`
do
  _fontdir="/usr/local/share/fonts/${_fontdir}"
  ls "${_fontdir}" | grep -qE ".ttf"
  if [ $? -eq 0 ] ; then
    #Got a good font directory
    _tmp="${_tmp}
  FontPath     \"${_fontdir}\""
  fi
done
#Now close off the section
_tmp="${_tmp}
EndSection
"
# And save it over the built-in xorg.conf.d config file
echo "${_tmp}" > "${_conf}"
