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
	struct ioam_node node =
	{
		.ioam_node_id = 1,

		.if_nb = 2,
		.ifs =
		{
			{
				.ioam_if_id = 11,
				.if_name = "h_athos1",
				.ioam_if_mode = IOAM_IF_MODE_NONE
			},
			{
				.ioam_if_id = 12,
				.if_name = "h_athos2",
				.ioam_if_mode = IOAM_IF_MODE_EGRESS,
				.encap_dst = "db02::2"
			}
		},

		.ns_nb = 2,
		.nss =
		{
			{ .ns_id = IOAM_DEFAULT_NS_ID },
			{
				.ns_id = 123,
				.data = 0x12345678
			}
		},

		.encap_freq = 1,
		.encap_nb = 1,
		.encaps =
		{
			{
				.namespace_id = 123,
				.if_name = "h_athos2",
				.trace =
				{
					.enabled = true,
					.hop_nb = 3,
					.type = IOAM_TRACE_TYPE_0 | IOAM_TRACE_TYPE_1
				},
				/*.pot =
				{
					.enabled = true,
					.profile = IOAM_POT_PROFILE_1,
					.type = IOAM_POT_TYPE_0
				},
				.e2e =
				{
					.enabled = true,
					.inside_hbh = true,
					.type = IOAM_E2E_TYPE_1
				}*/
			}
		}
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

