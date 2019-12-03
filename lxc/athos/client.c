#include <stdio.h>
#include <sys/socket.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdint.h>

#define SOCKET_IOAM 333

#define SERVER "db02::2"
#define PORT 8080

/*
 * Simulates an HTTP request over an IOAM socket
 * (ie injects an OpenTelemetry span-ID to the dataplane)
 */
void http_request(int socket, char *data, uint64_t span_id)
{
	int fd;

	/*
	 * Get an IOAM socket decorator based on master socket
	 */
	if ((fd = syscall(SOCKET_IOAM, socket, span_id)) < 0) {
		printf("ioam socket error (%d)\n", fd);
		return;
	}

	send(fd, data, strlen(data), 0);
	close(fd);
}

int main()
{
	struct sockaddr_in6 end_point;
	int fd;

	if ((fd = socket(AF_INET6, SOCK_STREAM, 0)) < 0) {
		printf("socket error (%d)\n", fd);
		return 1;
	}

	end_point.sin6_family = AF_INET6;
	end_point.sin6_port = htons(PORT);
	if (inet_pton(AF_INET6, SERVER, &end_point.sin6_addr) <= 0) {
		printf("inet_pton error\n");
		close(fd);
		return 1;
	}

	if (connect(fd, (struct sockaddr *)&end_point,
					sizeof(end_point)) < 0) {
		printf("connect error\n");
		close(fd);
		return 1;
	}

	http_request(fd, "HTTP request A", 0x1A2342DC8C721528);
	http_request(fd, "HTTP request B", 0xBEB673652AFA51A2);
	http_request(fd, "HTTP request C", 0xCF39EEDAEBB25289);

	close(fd);
	return 0;
}

