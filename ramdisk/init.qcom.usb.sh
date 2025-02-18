#!/system/bin/sh
# Copyright (c) 2012, Code Aurora Forum. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of Code Aurora Forum, Inc. nor the names of its
#       contributors may be used to endorse or promote products derived
#      from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Update USB serial number from persist storage if present, if not update
# with value passed from kernel command line, if none of these values are
# set then use the default value. This order is needed as for devices which
# do not have unique serial number.
# User needs to set unique usb serial number to persist.usb.serialno
#
serialno=`getprop persist.usb.serialno`
case "$serialno" in
    "")
    serialnum=`getprop ro.serialno`
    case "$serialnum" in
        "");; #Do nothing, use default serial number
        *)
        echo "$serialnum" > /sys/class/android_usb/android0/iSerial
    esac
    ;;
    *)
    echo "$serialno" > /sys/class/android_usb/android0/iSerial
esac

chown root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

#
# Allow persistent usb charging disabling
# User needs to set usb charging disabled in persist.usb.chgdisabled
#
target=`getprop ro.board.platform`
usbchgdisabled=`getprop persist.usb.chgdisabled`
case "$usbchgdisabled" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8660")
        echo "$usbchgdisabled" > /sys/module/pmic8058_charger/parameters/disabled
        echo "$usbchgdisabled" > /sys/module/smb137b/parameters/disabled
	;;
        "msm8960")
        echo "$usbchgdisabled" > /sys/module/pm8921_charger/parameters/disabled
	;;
    esac
esac

usbcurrentlimit=`getprop persist.usb.currentlimit`
case "$usbcurrentlimit" in
    "") ;; #Do nothing here
    * )
    case $target in
        "msm8960")
        echo "$usbcurrentlimit" > /sys/module/pm8921_charger/parameters/usb_max_current
	;;
    esac
esac


#
# Allow USB enumeration with default PID/VID
#
#ifdef VENDOR_EDIT
#yansen@OnLine.SysSrv.USB, 2012/11/21, modify for user do not need diag com
# setprop sys.usb.config.extra diag
# setprop persist.service.adb.enable 1
#endif

baseband=`getprop ro.baseband`
echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
usb_config=`getprop persist.sys.usb.config`
case "$usb_config" in
    "" | "adb") #USB persist config not set, select default configuration
        case $target in
            "msm8974")
                setprop persist.sys.usb.config diag,adb
                ;;
            "msm8960")
                case "$baseband" in
                    "mdm")
                         #setprop persist.sys.usb.config diag,diag_mdm,serial_hsic,serial_tty,rmnet_hsic,mass_storage,adb
                         #added by songxh for wlan and rf test begain 2012-10-23
                         ftmmode=`getprop ro.wandrfmode`
                         case "$ftmmode" in
                             "1")
                                  setprop persist.sys.usb.config diag,adb
                             ;;
                             "2")
                                  setprop persist.sys.usb.config diag_mdm,adb
                             ;;
                             *)
                                  setprop persist.sys.usb.config mass_storage
                             ;;
                         esac
                         #added by songxh for wlan and rf test end 2012-10-23
                    ;;
                    "sglte")
                         setprop persist.sys.usb.config diag,diag_mdm,serial_smd,serial_tty,serial_hsuart,rmnet_hsuart,mass_storage,adb
                    ;;
                    *)
                         setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_bam,mass_storage,adb
                    ;;
                esac
            ;;
            "msm7627a")
                setprop persist.sys.usb.config diag,serial_smd,serial_tty,rmnet_smd,mass_storage,adb
            ;;
            * )
                case "$baseband" in
                    "svlte2a")
                         setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_smd,rmnet_smd_sdio,mass_storage,adb
                    ;;
                    "csfb")
                         setprop persist.sys.usb.config diag,diag_mdm,serial_sdio,serial_tty,rmnet_sdio,mass_storage,adb
                    ;;
                    *)
                         setprop persist.sys.usb.config diag,serial_tty,serial_tty,rmnet_smd,mass_storage,adb
                    ;;
                esac
            ;;
        esac
    ;;
    * ) 
        #added by songxh for wlan and rf test begain 2013-01-10
        ftmmode=`getprop ro.wandrfmode`
        case "$ftmmode" in
           "1")
                 setprop persist.sys.usb.config diag,adb
           ;;
           "2")
                 setprop persist.sys.usb.config diag_mdm,adb
           ;;
       esac
       #added by songxh for wlan and rf test end 2013-01-10   
    ;; #USB persist config exists, do nothing
esac

#
# Add support for exposing lun0 as cdrom in mass-storage
#
target=`getprop ro.product.device`
cdromname="/system/etc/cdrom_install.iso"
cdromenable=`getprop persist.service.cdrom.enable`
case "$target" in
        "msm7627a" | "msm8625")
                case "$cdromenable" in
                        0)
                                echo "" > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                ;;
                        1)
                                echo "mounting usbcdrom lun"
                                echo $cdromname > /sys/class/android_usb/android0/f_mass_storage/lun0/file
                                ;;
                esac
                ;;
esac
