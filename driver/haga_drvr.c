/*
 * HAGA driver
 *
 */

#include <linux/fs.h>
#include <linux/init.h>
#include <linux/module.h>
#include <linux/pci.h>

#define LCL_DEBUG_ALL 0

#define LCL_DEBUG_LEVEL LCL_DEBUG_ALL

#define PCI_DEVICE_ID_TSP_COP 0x5050

MODULE_LICENSE("GPL");

static struct pci_device_id ids[] = {
	{ PCI_DEVICE(PCI_VENDOR_ID_XILINX, PCI_DEVICE_ID_TSP_COP), },
	{ 0, }
};
MODULE_DEVICE_TABLE(pci, ids);

/* File operaitons */
int haga_open(struct inode *node, struct file *flip)
{
	printk(KERN_DEBUG "open()\n");

	return 0;
}

int haga_release(struct inode *node, struct file *flip)
{
	printk(KERN_DEBUG "release()\n");

	return 0;
}

static int probe(struct pci_dev *dev, const struct pci_device_id *id)
{
	pci_enable_device(dev);

#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT "We have got a device\n");
#endif

	return 0;
}

static void remove(struct pci_dev *dev)
{
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
};

static int __init haga_init(void)
{
#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT "Loading haga-drvr.\n");
#endif /* LCL_DEBUG_LEVEL */

	return pci_register_driver(&pci_driver);
}

static void __exit haga_exit(void)
{
#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT "Unloading haga-drvr.\n");
#endif /* LCL_DEBUG_LEVEL */

	pci_unregister_driver(&pci_driver);
}

module_init(haga_init);
module_exit(haga_exit);
