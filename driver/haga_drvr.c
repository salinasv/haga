/*
 * HAGA driver
 *
 */

#include <linux/init.h>
#include <linux/module.h>
 
MODULE_LICENSE("GPL");

static int __init haga_init(void)
{
	return 0;
}

static void __exit haga_exit(void)
{
}

module_init(haga_init);
module_exit(haga_exit);
