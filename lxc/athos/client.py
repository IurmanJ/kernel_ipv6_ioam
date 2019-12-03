#!/usr/bin/env python3

import socket
import ctypes
from opentelemetry import trace
from opentelemetry.context import Context
from opentelemetry.sdk.trace import Tracer
from opentelemetry.sdk.trace.export import ConsoleSpanExporter
from opentelemetry.sdk.trace.export import SimpleExportSpanProcessor

SYS_socket_ioam = 333

HOST = 'db02::2'
PORT = 8080

libc = ctypes.CDLL(None)
_getsocket_ioam_syscall = libc.syscall
_getsocket_ioam_syscall.restypes = ctypes.c_int
_getsocket_ioam_syscall.argtypes = ctypes.c_int, ctypes.c_int, ctypes.c_uint64

trace.set_preferred_tracer_implementation(lambda T: Tracer())
tracer = trace.tracer()
tracer.add_span_processor(SimpleExportSpanProcessor(ConsoleSpanExporter()))

def ioam_http_request(fd, msg, span_id):
	ioam_fd = _getsocket_ioam_syscall(SYS_socket_ioam, fd, span_id)
	if ioam_fd < 0:
		raise OSError(ctypes.get_errno(), 'ioam_http_request() failed')

	with socket.socket(fileno=ioam_fd) as ioam_socket:
		ioam_socket.send(msg)

with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as s:
	s.connect((HOST, PORT))

	with tracer.start_as_current_span('requestA'):
		ioam_http_request(s.fileno(), 'HTTP request A'.encode(), tracer.get_current_span().context.span_id)

	with tracer.start_as_current_span('requestB'):
		ioam_http_request(s.fileno(), 'HTTP request B'.encode(), tracer.get_current_span().context.span_id)

	with tracer.start_as_current_span('requestC'):
		ioam_http_request(s.fileno(), 'HTTP request C'.encode(), tracer.get_current_span().context.span_id)

