/*
 * HAGA driver
 *
 */

#include <linux/init.h>
#include <linux/module.h>

#define LCL_DEBUG_ALL 0

#define LCL_DEBUG_LEVEL LCL_DEBUG_ALL
 
MODULE_LICENSE("GPL");

static int __init haga_init(void)
{
#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT "Loading haga-drvr\n");
#endif /* LCL_DEBUG_LEVEL */
	return 0;
}

static void __exit haga_exit(void)
{
#if LCL_DEBUG_LEVEL >= LCL_DEBUG_ALL
	printk(KERN_ALERT "Unloading haga-drvr\n");
#endif /* LCL_DEBUG_LEVEL */
}

module_init(haga_init);
module_exit(haga_exit);
