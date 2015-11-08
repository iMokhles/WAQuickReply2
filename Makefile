GO_EASY_ON_ME = 1

DEBUG = 0

ARCHS = armv7 armv7s arm64

THEOS_DEVICE_IP = localhost

TARGET = iphone:clang:latest:8.0

export ADDITIONAL_LDFLAGS = -Wl,-segalign,4000

THEOS_BUILD_DIR = Packages

include theos/makefiles/common.mk

TWEAK_NAME = WAQuickReply2
WAQuickReply2_CFLAGS = -fobjc-arc
WAQuickReply2_FILES = WAQuickReply2.xm WAQuickReply2Helper.m $(wildcard FMDB/*.m)
WAQuickReply2_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore CoreImage Accelerate AVFoundation AudioToolbox MobileCoreServices Social Accounts AssetsLibrary AdSupport MediaPlayer SystemConfiguration Security ImageIO MapKit Accelerate CoreText MessageUI CoreMedia AddressBookUI
WAQuickReply2_PRIVATE_FRAMEWORKS = AppSupport ChatKit CoreTelephony XPCKit IMCore BackBoardServices GraphicsServices MobileCoreServices Preferences FrontBoard
WAQuickReply2_LIBRARIES = substrate MobileGestalt sqlite3 z stdc++.6 imounbox imodevtools2

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
