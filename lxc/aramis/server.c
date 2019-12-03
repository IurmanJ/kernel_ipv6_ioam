#include <stdio.h>
#include <sys/socket.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <string.h>

#define SERVER "db02::2"
#define PORT 8080

int main()
{ 
	int server_fd, client_socket, value;
	struct sockaddr_in6 address;
	int opt = 1;
	int addrlen = sizeof(address);
	char buffer[14] = {0};
       
	if (!(server_fd = socket(AF_INET6, SOCK_STREAM, 0))) {
		perror("socket");
		return 1;
	}
       
	if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR | SO_REUSEPORT,
					&opt, sizeof(opt))) {
		close(server_fd);
		perror("setsockopt");
		return 1;
	}

	address.sin6_family = AF_INET6;
	address.sin6_port = htons(PORT);
	if (inet_pton(AF_INET6, SERVER, &address.sin6_addr) <= 0) {
		close(server_fd);
		perror("inet_pton");
		return 1;
	}
       
	if (bind(server_fd, (struct sockaddr *)&address,
                                 	sizeof(address)) < 0) {
		close(server_fd);
		perror("bind");
		return 1;
	}

	if (listen(server_fd, 1) < 0) {
		close(server_fd);
		perror("listen");
		return 1;
	}

	if ((client_socket = accept(server_fd, (struct sockaddr *)&address,
					(socklen_t*)&addrlen)) < 0) {
		close(server_fd);
		perror("accept");
		return 1;
	}

	while(1) {
		value = read(client_socket, buffer, 14);
		if (!value)
			break;

		printf("%s\n", buffer);
	}

    close(client_socket);
    close(server_fd);
    return 0;
}

