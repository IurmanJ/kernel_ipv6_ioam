#include <stdlib.h>
#include <stdio.h>
#include <linux/ioam.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>

int main()
{
	int ret, fd;

	fd = open("/dev/ioam", O_RDWR);
	if (fd == -1)
	{
		printf("Unable to open the ioam device\n");
		return 1;
	}

	ret = ioctl(fd, IOAM_IOC_UNREGISTER);
	if (ret == IOAM_RET_OK)
		printf("OK\n");
	else
		printf("ERROR (%d)\n", ret);

	close(fd);
	return 0;
}

