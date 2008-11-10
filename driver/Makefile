
# If KERNELRELEASE is defined, we've been invoked from the kernel
# build system and can use its languaje.
ifneq ($(KERNELRELEASE),)
	obj-m := haga_drvr.o

# Otherwise we are called directly from the command line
# invoque the kernel build system
else
	KERNELDIR ?= /lib/modules/$(shell uname -r)/build
	PWD := $(shell pwd)

default:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) modules

endif

clean:
	echo "clean"
	rm -rf *.o core .depend .*.cmd *.ko *.mod.c .tmp_versions
