CC      = $(CC_PREFIX)-gcc
CFLAGS  = -std=c11 -O2 -ffreestanding -mno-red-zone -fno-stack-protector -Wshadow -Wall -Wunused -Werror-implicit-function-declaration -Werror -fshort-wchar -Wall -fno-builtin -mno-mmx -mno-sse -maccumulate-outgoing-args
CFLAGS += -I$(GNUEFI_INC) -I$(GNUEFI_INC)/$(GNUEFI_ARCH) -I$(GNUEFI_INC)/protocol
LDFLAGS = -nostdlib -shared -Wl,-dll -Wl,--subsystem,10 -e _EfiMain
LIBS    = -L$(GNUEFI_LIB) -lefi -lgcc

GNUEFI_INC = gnu-efi-out/$(CC_PREFIX)/include/efi
GNUEFI_LIB = gnu-efi-out/$(CC_PREFIX)/lib

FILES_C = src/main.c src/util.c src/types.c src/config.c
FILES_H = $(wildcard src/*.h)
FILES_CS = src/Setup.cs src/Esp.cs src/Efi.cs
GIT_DESCRIBE = $(firstword $(shell git describe --tags) unknown)
CFLAGS += '-DGIT_DESCRIBE=L"$(GIT_DESCRIBE)"'
ZIPDIR = HackBGRT-$(GIT_DESCRIBE:v%=%)
ZIP = $(ZIPDIR).zip

all: gnu-efi efi setup zip
efi: bootx64.efi bootia32.efi
setup: setup.exe

.PHONY: clean testx64-qemu gnu-efi-x64 gnu-efi-ia32

zip: $(ZIP)
$(ZIP): bootx64.efi bootia32.efi config.txt splash.bmp setup.exe README.md CHANGELOG.md README.efilib LICENSE
	test ! -d "$(ZIPDIR)"
	mkdir "$(ZIPDIR)"
	cp -a $^ "$(ZIPDIR)" || (rm -rf "$(ZIPDIR)"; exit 1)
	7z a -mx=9 "$(ZIP)" "$(ZIPDIR)" || (rm -rf "$(ZIPDIR)"; exit 1)
	rm -rf "$(ZIPDIR)"

src/GIT_DESCRIBE.cs: $(FILES_CS) $(FILES_C) $(FILES_H)
	echo 'public class GIT_DESCRIBE { public const string data = "$(GIT_DESCRIBE)"; }' > $@

setup.exe: $(FILES_CS) src/GIT_DESCRIBE.cs
	csc /define:GIT_DESCRIBE /out:$@ $^

bootx64.efi: CC_PREFIX = x86_64-w64-mingw32
bootx64.efi: GNUEFI_ARCH = x86_64
bootx64.efi: $(FILES_C)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS) -s

bootia32.efi: CC_PREFIX = i686-w64-mingw32
bootia32.efi: GNUEFI_ARCH = ia32
bootia32.efi: $(FILES_C)
	$(CC) $(CFLAGS) $(LDFLAGS) $^ -o $@ $(LIBS) -s

clean:
	rm -f bootx64.efi bootia32.efi
	rm -rf gnu-efi-out/
	$(MAKE) -C submodules/gnu-efi clean
	rm -f setup.exe
	rm -rf efi_test/

testx64-qemu: gnu-efi bootx64.efi config.txt splash.bmp
	mkdir -p efi_test/EFI/HackBGRT
	cp bootx64.efi efi_test/EFI/HackBGRT/loader.efi && echo "bootx64 okay"
	cp config.txt splash.bmp efi_test/EFI/HackBGRT/ && echo "aux files okay"
	echo 'fs0:\EFI\HackBGRT\loader.efi' > efi_test/startup.nsh
	qemu-system-x86_64 -L /usr/share/ovmf/ --bios OVMF.fd -drive media=disk,file=fat:rw:./efi_test,format=raw -net none -serial stdio

gnu-efi: gnu-efi-x64 gnu-efi-ia32

gnu-efi-x64:
	$(MAKE) -C submodules/gnu-efi ARCH=x86_64 CC=x86_64-w64-mingw32-gcc lib
	
	mkdir -p gnu-efi-out/x86_64-w64-mingw32/include
	mkdir -p gnu-efi-out/x86_64-w64-mingw32/lib
	
	cp -a submodules/gnu-efi/inc gnu-efi-out/x86_64-w64-mingw32/include/efi
	cp -a submodules/gnu-efi/x86_64/lib/libefi.a gnu-efi-out/x86_64-w64-mingw32/lib/libefi.a

gnu-efi-ia32:
	$(MAKE) -C submodules/gnu-efi ARCH=ia32 CC=i686-w64-mingw32-gcc lib
	
	mkdir -p gnu-efi-out/i686-w64-mingw32/include
	mkdir -p gnu-efi-out/i686-w64-mingw32/lib
	
	cp -a submodules/gnu-efi/inc gnu-efi-out/i686-w64-mingw32/include/efi
	cp -a submodules/gnu-efi/ia32/lib/libefi.a gnu-efi-out/i686-w64-mingw32/lib/libefi.a
