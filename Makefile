obj-m := pcm5102a.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install:
	sudo cp pcm5102a.ko /lib/modules/$(shell uname -r)
	sudo depmod -a
