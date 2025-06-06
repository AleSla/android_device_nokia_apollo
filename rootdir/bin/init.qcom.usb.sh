#!/vendor/bin/sh
# Copyright (c) 2012-2018, 2020-2021 The Linux Foundation. All rights reserved.
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
#     * Neither the name of The Linux Foundation nor the names of its
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

# Set platform variables
soc_hwplatform=`cat /sys/devices/soc0/hw_platform 2> /dev/null`
soc_machine=`cat /sys/devices/soc0/machine 2> /dev/null`
soc_machine=${soc_machine:0:2}
soc_id=`cat /sys/devices/soc0/soc_id 2> /dev/null`

#
# Check ESOC for external modem
#
# Note: currently only a single MDM/SDX is supported
#
esoc_name=`cat /sys/bus/esoc/devices/esoc0/esoc_name 2> /dev/null`

target=`getprop ro.board.platform`

#
# Override USB default composition
#
# If USB persist config not set, set default configuration
if [ "$(getprop persist.vendor.usb.config)" == "" -a "$(getprop ro.build.type)" != "user" -a \
	"$(getprop init.svc.vendor.usb-gadget-hal-1-0)" != "running" ]; then
    if [ "$esoc_name" != "" ]; then
	  setprop persist.vendor.usb.config diag,diag_mdm,qdss,qdss_mdm,serial_cdev,dpl,rmnet,adb
    else
	  case "$(getprop ro.baseband)" in
	      "apq")
	          setprop persist.vendor.usb.config diag,adb
	      ;;
	      *)
	      case "$soc_hwplatform" in
	          "Dragon" | "SBC")
	              setprop persist.vendor.usb.config diag,adb
	          ;;
                  *)
		  case "$soc_machine" in
		    "SA")
	              setprop persist.vendor.usb.config diag,adb
		    ;;
		    *)
	            case "$target" in
	              "msm8996")
	                  setprop persist.vendor.usb.config diag,serial_cdev,serial_tty,rmnet_ipa,mass_storage,adb
		      ;;
	              "msm8909")
		          setprop persist.vendor.usb.config diag,serial_smd,rmnet_qti_bam,adb
		      ;;
	              "msm8937")
			    if [ -d /config/usb_gadget ]; then
				       setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,adb
			    else
			               case "$soc_id" in
				               "313" | "320")
				                  setprop persist.vendor.usb.config diag,serial_smd,rmnet_ipa,adb
				               ;;
				               *)
				                  setprop persist.vendor.usb.config diag,serial_smd,rmnet_qti_bam,adb
				               ;;
			               esac
			    fi
		      ;;
	              "msm8953")
			      if [ -d /config/usb_gadget ]; then
				      setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,adb
			      else
				      setprop persist.vendor.usb.config diag,serial_smd,rmnet_ipa,adb
			      fi
		      ;;
	              "msm8998" | "sdm660" | "apq8098_latv")
		          setprop persist.vendor.usb.config diag,serial_cdev,rmnet,adb
		      ;;
	              "sdm845" | "sdm710")
		          setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,adb
		      ;;
	              "msmnile")
		               case "$soc_id" in
			               "362" | "367")
			                  #setprop persist.vendor.usb.config diag,adb
			               ;;
			               *)
			                  #setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,qdss,adb
			               ;;
		               esac
		      ;;
	              "gen4")
			  #setprop persist.vendor.usb.config adb
		      ;;
	              "sm6150" | "trinket" | "lito" | "atoll" | "bengal" | "lahaina" | "holi")
			  #setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,qdss,adb
		      ;;
	              "monaco")
		          setprop persist.vendor.usb.config diag,qdss,rmnet,adb
		      ;;
	              *)
		          setprop persist.vendor.usb.config diag,adb
		      ;;
                    esac
		    ;;
		  esac
	          ;;
	      esac
	      ;;
	  esac
      fi
fi

# This check is needed for GKI 1.0 targets where QDSS is not available
if [ "$(getprop persist.vendor.usb.config)" == "diag,serial_cdev,rmnet,dpl,qdss,adb" -a \
     ! -d /config/usb_gadget/g1/functions/qdss.qdss ]; then
      setprop persist.vendor.usb.config diag,serial_cdev,rmnet,dpl,adb
fi

# Start peripheral mode on primary USB controllers for Automotive platforms
case "$soc_machine" in
    "SA")
	if [ -f /sys/bus/platform/devices/a600000.ssusb/mode ]; then
	    default_mode=`cat /sys/bus/platform/devices/a600000.ssusb/mode`
	    case "$default_mode" in
		"none")
		    echo peripheral > /sys/bus/platform/devices/a600000.ssusb/mode
		;;
	    esac
	fi
    ;;
esac

# check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
	# Chip-serial is used for unique MSM identification in Product string
	msm_serial=`cat /sys/devices/soc0/serial_number`;
	# If MSM serial number is not available, then keep it blank instead of 0x00000000
	if [ "$msm_serial" != "" ]; then
		msm_serial_hex=`printf %08X $msm_serial`
	fi

	machine_type=`cat /sys/devices/soc0/machine`
	#setprop vendor.usb.product_string "$machine_type-$soc_hwplatform _SN:$msm_serial_hex"
	#zhongli.liu modified for [SYS-017][USB Enumeration] Product name MUST show for transfer mode in host (Win,Mac,Ubuntu)
	#product_model=`getprop ro.product.model`
	#zhongli.liu modified for SNT-4339 The ro.product.nickname value is used on everywhere where the customer can see the device name
	product_model=`getprop ro.vendor.product.nickname`
	if ["$product_model" == ""]; then
	        product_model=`getprop ro.product.model`
	fi		
	setprop vendor.usb.product_string "$product_model"
	
	# ADB requires valid iSerialNumber; if ro.serialno is missing, use dummy
	serialnumber=`cat /config/usb_gadget/g1/strings/0x409/serialnumber 2> /dev/null`
	if [ "$serialnumber" == "" ]; then
		serialno=1234567
		echo $serialno > /config/usb_gadget/g1/strings/0x409/serialnumber
	fi
	setprop vendor.usb.configfs 1
fi

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.vendor.usb.config.extra`
if [ "$diag_extra" == "" ]; then
	setprop persist.vendor.usb.config.extra none
fi

# enable rps cpus on msm8937 target
setprop vendor.usb.rps_mask 0
case "$soc_id" in
	"294" | "295" | "353" | "354")
		setprop vendor.usb.rps_mask 40
	;;
esac

#
# Initialize UVC conifguration.
#
if [ -d /config/usb_gadget/g1/functions/uvc.0 ]; then
	cd /config/usb_gadget/g1/functions/uvc.0

	echo 3072 > streaming_maxpacket
	echo 10 > streaming_maxburst
	mkdir control/header/h
	ln -s control/header/h control/class/fs/
	ln -s control/header/h control/class/ss

	mkdir -p streaming/uncompressed/u/360p
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/360p/dwFrameInterval
	echo 333333 > streaming/uncompressed/u/360p/dwDefaultFrameInterval

	mkdir -p streaming/uncompressed/u/720p
	echo 1280 > streaming/uncompressed/u/720p/wWidth
	echo 720 > streaming/uncompressed/u/720p/wHeight
	echo 29491200 > streaming/uncompressed/u/720p/dwMinBitRate
	echo 29491200 > streaming/uncompressed/u/720p/dwMaxBitRate
	echo 1843200 > streaming/uncompressed/u/720p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/uncompressed/u/720p/dwDefaultFrameInterval
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/720p/dwFrameInterval

	mkdir -p streaming/uncompressed/u/1080p
	echo 1920 > streaming/uncompressed/u/1080p/wWidth
	echo 1080 > streaming/uncompressed/u/1080p/wHeight
	echo 66355200 > streaming/uncompressed/u/1080p/dwMinBitRate
	echo 995328000 > streaming/uncompressed/u/1080p/dwMaxBitRate
	echo 4147200 > streaming/uncompressed/u/1080p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/uncompressed/u/1080p/dwDefaultFrameInterval
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u/1080p/dwFrameInterval

	mkdir -p streaming/uncompressed/u1/360p
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/uncompressed/u1/360p/dwFrameInterval
	echo 333333 > streaming/uncompressed/u1/360p/dwDefaultFrameInterval

	mkdir -p streaming/mjpeg/m1/360p
	echo 640 > streaming/mjpeg/m1/360p/wWidth
	echo 360 > streaming/mjpeg/m1/360p/wHeight
	echo 460800   > streaming/mjpeg/m1/360p/dwMaxVideoFrameBufferSize
	echo 18432000  > streaming/mjpeg/m1/360p/dwMinBitRate
	echo 55296000 > streaming/mjpeg/m1/360p/dwMaxBitRate
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m1/360p/dwFrameInterval
	echo 333333 > streaming/mjpeg/m1/360p/dwDefaultFrameInterval

	mkdir -p streaming/mjpeg/m1/720p
	echo 1280 > streaming/mjpeg/m1/720p/wWidth
	echo 720 > streaming/mjpeg/m1/720p/wHeight
	echo 29491200 > streaming/mjpeg/m1/720p/dwMinBitRate
	echo 29491200 > streaming/mjpeg/m1/720p/dwMaxBitRate
	echo 1843200 > streaming/mjpeg/m1/720p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m1/720p/dwDefaultFrameInterval
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m1/720p/dwFrameInterval

	mkdir -p streaming/mjpeg/m1/1080p
	echo 1920 > streaming/mjpeg/m1/1080p/wWidth
	echo 1080 > streaming/mjpeg/m1/1080p/wHeight
	echo 66355200 > streaming/mjpeg/m1/1080p/dwMinBitRate
	echo 995328000 > streaming/mjpeg/m1/1080p/dwMaxBitRate
	echo 4147200 > streaming/mjpeg/m1/1080p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m1/1080p/dwDefaultFrameInterval
	echo -e "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m1/1080p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/360p
	echo 640 > streaming/mjpeg/m/360p/wWidth
	echo 360 > streaming/mjpeg/m/360p/wHeight
	echo 460800   > streaming/mjpeg/m/360p/dwMaxVideoFrameBufferSize
	echo 18432000  > streaming/mjpeg/m/360p/dwMinBitRate
	echo 55296000 > streaming/mjpeg/m/360p/dwMaxBitRate
	echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/360p/dwFrameInterval
	echo 333333 > streaming/mjpeg/m/360p/dwDefaultFrameInterval

	mkdir -p streaming/mjpeg/m/720p
	echo 1280 > streaming/mjpeg/m/720p/wWidth
	echo 720 > streaming/mjpeg/m/720p/wHeight
	echo 29491200 > streaming/mjpeg/m/720p/dwMinBitRate
	echo 29491200 > streaming/mjpeg/m/720p/dwMaxBitRate
	echo 1843200 > streaming/mjpeg/m/720p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m/720p/dwDefaultFrameInterval
	echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/720p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/1080p
	echo 1920 > streaming/mjpeg/m/1080p/wWidth
	echo 1080 > streaming/mjpeg/m/1080p/wHeight
	echo 66355200 > streaming/mjpeg/m/1080p/dwMinBitRate
	echo 995328000 > streaming/mjpeg/m/1080p/dwMaxBitRate
	echo 4147200 > streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m/1080p/dwDefaultFrameInterval
	echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/1080p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/1440p
	echo 2560 > streaming/mjpeg/m/1440p/wWidth
	echo 1440 > streaming/mjpeg/m/1440p/wHeight
	echo 117964800 > streaming/mjpeg/m/1440p/dwMinBitRate
	echo 1769472000 > streaming/mjpeg/m/1440p/dwMaxBitRate
	echo 7372800 > streaming/mjpeg/m/1440p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m/1440p/dwDefaultFrameInterval
	echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/1440p/dwFrameInterval

	mkdir -p streaming/mjpeg/m/2160p
	echo 3840 > streaming/mjpeg/m/2160p/wWidth
	echo 2160 > streaming/mjpeg/m/2160p/wHeight
	echo 265420800 > streaming/mjpeg/m/2160p/dwMinBitRate
	echo 3981312000 > streaming/mjpeg/m/2160p/dwMaxBitRate
	echo 16588800 > streaming/mjpeg/m/2160p/dwMaxVideoFrameBufferSize
	echo 333333 > streaming/mjpeg/m/2160p/dwDefaultFrameInterval
	echo "333333\n666666\n1000000\n5000000\n" > streaming/mjpeg/m/2160p/dwFrameInterval

	echo 0x04 > /config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m/bmaControls
	echo 0x04 > /config/usb_gadget/g1/functions/uvc.0/streaming/mjpeg/m1/bmaControls

	mkdir -p streaming/h264/h/960p
	echo 1920 > streaming/h264/h/960p/wWidth
	echo 960 > streaming/h264/h/960p/wHeight
	echo 40 > streaming/h264/h/960p/bLevelIDC
	echo "333667\n" > streaming/h264/h/960p/dwFrameInterval

	mkdir -p streaming/h264/h/1920p
	echo "333667\n" > streaming/h264/h/1920p/dwFrameInterval

	mkdir streaming/header/h
	mkdir streaming/header/h1
	ln -s streaming/uncompressed/u1 streaming/header/h1
	ln -s streaming/mjpeg/m1 streaming/header/h1
	ln -s streaming/uncompressed/u streaming/header/h
	ln -s streaming/mjpeg/m streaming/header/h
	ln -s streaming/h264/h streaming/header/h
	ln -s streaming/header/h1 streaming/class/fs/
	ln -s streaming/header/h1 streaming/class/hs/
	ln -s streaming/header/h streaming/class/ss/
fi
