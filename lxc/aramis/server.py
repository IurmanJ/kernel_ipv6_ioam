#!/usr/bin/env python3

import socket

HOST = 'db02::2'
PORT = 8080

with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as s:
	s.bind((HOST, PORT))
	s.listen()
	conn, addr = s.accept()
	with conn:
		while True:
			data = conn.recv(14)
			if not data:
				break
			print(data.decode())

