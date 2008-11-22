/*
 * HAGA driver
 *
 */

//#include <linux/cdev.h>
#include <asm/uaccess.h> 	/* get/put_user() */
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/pci.h>

#define LCL_DEBUG_ALL 0

#define LCL_DEBUG_LEVEL LCL_DEBUG_ALL
#define DRV_HGA "haga: "

#define PCI_DEVICE_ID_TSP_COP 0x5050

MODULE_LICENSE("GPL");

static struct pci_device_id ids[] = {
	{ PCI_DEVICE(PCI_VENDOR_ID_XILINX, PCI_DEVICE_ID_TSP_COP), },
	{ 0, }
};
MODULE_DEVICE_TABLE(pci, ids);

struct cdev *cdevice;

/* BAR address */
static u32 __iomem *pci_bar0;
static u32 __iomem *pci_bar1;
 
/* File operaitons */
int haga_open(struct inode *node, struct file *flip)
{
	printk(KERN_DEBUG DRV_HGA "open()\n");

	return 0;
}

int haga_release(struct inode *node, struct file *flip)
{
	printk(KERN_DEBUG DRV_HGA "release()\n");

	return 0;
}

ssize_t read(struct file *file, char __user *buf, size_t count, loff_t *offset)
{
	u32 data;

	data = readl(pci_bar0 + *offset);

	printk(KERN_INFO DRV_HGA "you just read %X using %X offset size %d\n", data,
			(unsigned int)*offset, count);

	put_user(data, (u32*)buf);

	return sizeof(data);
}

ssize_t write(struct file *file, const char __user *buf,  size_t count, loff_t *offset)
{
	u32 data;
	int tmp;

	tmp = get_user(data, (u32*)buf);

	printk(KERN_INFO DRV_HGA "you want to write %x using %X offset, size %d\n", data,
			(unsigned int)*offset, count);

	writel(data, (pci_bar0 + *offset));

#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_DEBUG DRV_HGA "write()\n");
#endif
	return 1;
}

static int probe(struct pci_dev *dev, const struct pci_device_id *id)
{
	unsigned long bar_addr;
	unsigned long tmp;
	unsigned long size;

	pci_enable_device(dev);

#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT DRV_HGA "We have got a device\n");
#endif

	bar_addr = pci_resource_start(dev, 0);
	tmp = pci_resource_end(dev, 0);
	size = tmp - bar_addr;

	if(!request_mem_region(bar_addr, size, "haga")) {
		printk(KERN_INFO DRV_HGA "can't get I/O mem address 0x%1.lx\n", bar_addr);
		return -ENODEV;
	}

	printk(KERN_INFO DRV_HGA "mem requested, want to map io.\n");
	pci_bar0 = ioremap(bar_addr, size);

	printk(KERN_INFO DRV_HGA "IO mapped BAR0\n");

	bar_addr = pci_resource_start(dev, 1);
	tmp = pci_resource_end(dev, 1);
	size = tmp - bar_addr;

	if(!request_mem_region(bar_addr, size, "haga")) {
		printk(KERN_INFO DRV_HGA "can't get I/O mem address 0x%1.lx\n", bar_addr);
		return -ENODEV;
	}
	pci_bar1 = ioremap(bar_addr, size);

	return 0;
}

static void remove(struct pci_dev *dev)
{
	unsigned long bar_addr;
	unsigned long tmp;
	unsigned long size;

	bar_addr = pci_resource_start(dev, 0);
	tmp = pci_resource_end(dev, 0);
	size = tmp - bar_addr;

	iounmap((void __iomem *)pci_bar0);
	release_mem_region(bar_addr, size);

	bar_addr = pci_resource_start(dev, 1);
	tmp = pci_resource_end(dev, 1);
	size = tmp - bar_addr;

	iounmap((void __iomem *)pci_bar1);
	release_mem_region(bar_addr, size);

	pci_disable_device(dev);
}

static struct pci_driver pci_driver = {
	.name = "haga",
	.id_table = ids,
	.probe = probe,
	.remove = remove,
};

static struct file_operations haga_fop = {
	.owner = 	THIS_MODULE,
	.open = 	haga_open,
	.release = 	haga_release,
	.write = 	write,
	.read = 	read,
};

static struct miscdevice haga_misc_device = {
	.minor 	= MISC_DYNAMIC_MINOR,
	.name 	= "haga",
	.fops 	= &haga_fop,
};

static int __init haga_init(void)
{
	int result;

#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT DRV_HGA "Loading haga-drvr.\n");
#endif /* LCL_DEBUG_LEVEL */

	result = misc_register(&haga_misc_device);
	if (result) {
		printk(KERN_ERR DRV_HGA "misc_register failed with error code %d.\n", result);
	}

	return pci_register_driver(&pci_driver);
}

static void __exit haga_exit(void)
{

#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT DRV_HGA "Unloading haga-drvr.\n");
#endif /* LCL_DEBUG_LEVEL */
	misc_deregister(&haga_misc_device);
	pci_unregister_driver(&pci_driver);
}

module_init(haga_init);
module_exit(haga_exit);
