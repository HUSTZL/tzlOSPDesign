#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/sched.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Haofei Hou HUST");
MODULE_DESCRIPTION("A simple example Linux module.");

static char* name="yuechuhaoxi";
module_param(name, charp, 0644);

static int code_init(void) {
	printk(KERN_INFO"Hello, %s!\n", name);
	return 0;
}

static void code_exit(void){
	printk(KERN_INFO"Goodbye, %s!\n", name);
}

module_init(code_init);
module_exit(code_exit);