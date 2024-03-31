extends Node

signal connected
signal on_receive
signal disconnected
signal error

var _status: int = 0
var _stream: StreamPeerTCP = StreamPeerTCP.new()

func _ready() -> void:
	_status = _stream.get_status()

func connect_to_host(host:String, port: int) -> void:
	print("Connection to %s:%d" % [host, port])
	
	_status = _stream.STATUS_NONE
	if _stream.connect_to_host(host, port) != OK:
		print("Error connection to host.")
		emit_signal("error")

func send(data: PackedByteArray) -> bool:
	if _status != _stream.STATUS_CONNECTED:
		print("Error: Stream is currently not connected.")
		return false
	var error:int = _stream.put_data(data)
	if error != OK:
		print("Error writing to stream ", error)
		return false
	return true

func _verify_event(status: int) -> void:
	match status:
		_stream.STATUS_NONE:
			print("Disconnected from host.")
			emit_signal("disconnected")
		_stream.STATUS_CONNECTING:
			print("Connecting to host.")
		_stream.STATUS_CONNECTED:
			print("Connected to host.")
			emit_signal("connected")
		_stream.STATUS_ERROR:
			print("Error with socekt stream")
			emit_signal("error")

func poll(delta: float) -> void:
	_stream.poll()
	var new_status: int = _stream.get_status()
	if new_status != _status:
		_status = new_status
		_verify_event(_status)
	
	if _status == _stream.STATUS_CONNECTED:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			#print("Available bytes: ", available_bytes)
			var data: Array = _stream.get_partial_data(available_bytes)
			if data[0] != OK:
				print("Error getting data from stream: ", data[0])
				emit_signal("error")
			else:
				emit_signal("on_receive", data[1])
		
