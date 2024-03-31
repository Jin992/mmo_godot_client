extends Node

const HOST: String = "127.0.0.1"
const PORT: int = 3333
const RECONNECT_TIMEOUT: float = 3.0

const mmoProto = preload("res://proto/serverRequest.gd")
const ServerResponse = preload("res://proto/serverResponse.gd")
const TcpSocket = preload("res://mmo/net/tcp_socket.gd")

var _socket = TcpSocket.new()
var thread = Thread.new()

func socket_connect() -> void:
	_socket.connect("connected", _handle_client_connected)
	_socket.connect("disconnected", _handle_client_disconnected)
	_socket.connect("error", _handle_client_error)
	_socket.connect("on_receive", _handle_client_data)
	add_child(_socket)
	thread.start(_thread_func)
	_socket.connect_to_host(HOST, PORT)
	
	
func send(req: mmoProto.ServerRequest) -> void:
	var packed_bytes: PackedByteArray = req.to_bytes()
	print("Send size: ", packed_bytes.size())
	_socket.send(packed_bytes)

func _connect_after_timeout(timeout: float) -> void:
	await get_tree().create_timer(timeout).timeout # Delay for timeout
	_socket.connect_to_host(HOST, PORT)

func _handle_client_connected() -> void:
	print("Client connected to server.")

func _handle_client_disconnected() -> void:
	print("Client disconnected from server.")
	_connect_after_timeout(RECONNECT_TIMEOUT)
	
func _handle_client_error() -> void:
	print("Client error.")
	_connect_after_timeout(RECONNECT_TIMEOUT)
	
func _handle_client_data(data: PackedByteArray) -> void:
	print("Client data size: ", data.size())
	#var message: PoolByteArray = [97, 99, 107] # Bytes for "ack" in ASCII
	#_socket.send(data)

func _thread_func() -> void:
	print("Starting socket poll thread")
	while true:
		_socket.poll(3.0)
