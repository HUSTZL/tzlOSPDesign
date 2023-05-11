#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/module.h>
#include <linux/device.h>
#include <linux/slab.h>

#define DevName "test"
#define ClassName "class_test"
MODULE_AUTHOR("Haofei Hou HUST");
MODULE_DESCRIPTION("A simple device for build a buffer");
MODULE_LICENSE("GPL");

struct class    *mem_class;
struct Pci_dev  *test_devices;
struct cdev 	_cdev;
dev_t  dev;

static char *device_buffer;
static size_t pos; 
#define MAX_DEVICE_BUFFER_SIZE 64

static int Test_open(struct inode *inode,struct file *filp)
{
	device_buffer = kmalloc(MAX_DEVICE_BUFFER_SIZE, GFP_KERNEL);
	pos = 0;
	return 0;
}

static int Test_release(struct inode *inode,struct file *filp)
{
	return 0;
}

static ssize_t 
Test_read(struct file *file, char __user *buf, size_t len, loff_t *ppos)
{
	if(pos < len)
		len = pos;
	if(copy_to_user(buf, device_buffer+pos-len, len)) {
		printk("read failed\n");
		return -EFAULT;
	}
	pos = pos-len;
	printk("%s: 读出%ld字节，读出后指针位置为%ld\n", __func__, len, pos);
	return len;
}

static ssize_t 
Test_write(struct file *file, const char __user *buf, size_t count, loff_t *f_pos)
{
	if(pos + count > 64)
		count = 64-pos;
	if(copy_from_user(device_buffer+pos, buf, count)) {
		printk("write failed\n");
		return -EFAULT;
	}
	pos = pos + count;
	printk("%s: 写入%ld字节，写完后缓冲区为%s\n", __func__, count, device_buffer);
	return count;
}

static struct file_operations test_fops = {
    .owner = THIS_MODULE,
    .open = Test_open,
    .release = Test_release,
    .read = Test_read,
    .write = Test_write,
};

static int Test_init_module(void) {//驱动入口函数
	//动态分配设备号
	int result = alloc_chrdev_region(&dev, 0, 2, DevName);
	if (result < 0) {
		printk("Err:failed in alloc_chrdev_region!\n");
		return result;
	}
	//创建class实例
	mem_class = class_create(THIS_MODULE,ClassName);// /dev/ create devfile 
	if (IS_ERR(mem_class)) {
		printk("Err:failed in creating class!\n");
  	}
  	//动态创建设备描述文件 /dev/test
	device_create(mem_class,NULL,dev,NULL,DevName);

	cdev_init(&_cdev,&test_fops);
	_cdev.owner = THIS_MODULE;
	_cdev.ops = &test_fops;//Create Dev and file_operations Connected
	result = cdev_add(&_cdev,dev,1);
	printk("dev open\n");
	return result;
}

static void Test_exit_module(void)//驱动退出函数
{
	kfree(device_buffer);
	if (0 != mem_class) {
	    device_destroy(mem_class,dev);
		class_destroy(mem_class);
		mem_class = 0;
	}
	cdev_del(&_cdev);
	printk("dev close\n");
}
module_init(Test_init_module);
module_exit(Test_exit_module);
MODULE_AUTHOR(DevName);
MODULE_LICENSE("GPL");
