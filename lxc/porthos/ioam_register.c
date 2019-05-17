#include <stdlib.h>
#include <stdio.h>
#include <linux/ioam.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <unistd.h>

int main()
{
	int ret, fd;

	// =============== Data structure ================
	struct ioam_node node = {
		.ioam_node_id = 2,
		.if_nb = 2,
		.ifs = {
		  { .ioam_if_id = 21, .if_name = "h_porthos1", .ioam_if_mode = IOAM_IF_MODE_INGRESS },
		  { .ioam_if_id = 22, .if_name = "h_porthos2", .ioam_if_mode = IOAM_IF_MODE_EGRESS },
		},
		.ns_nb = 2,
		.nss = {
		  { .ns_id = IOAM_DEFAULT_NS_ID, .ns_decap = 0 },
		  { .ns_id = 123, .ns_decap = 0 },
		},
		.encap_nb = 0,
		.encaps = { },
	};
	// ===============================================

	fd = open("/dev/ioam", O_RDWR);
	if (fd == -1)
	{
		printf("Unable to open the ioam device\n");
		return 1;
	}

	ret = ioctl(fd, IOAM_IOC_REGISTER, &node);
	if (ret == IOAM_RET_OK)
		printf("OK\n");
	else
		printf("ERROR (%d)\n", ret);

	close(fd);
	return 0;
}

