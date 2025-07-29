## Transport for running local simulations without need for major code restructuring
class_name LocalTransport extends EchonetTransport

func init_server() -> bool:
	if !super.init_server(): return false
	_connection_successful = true
	return true

func init_client() -> bool:
	push_warning("Cannot call 'init_client' using LocalTransport")
	return false

func init_server_info_request() -> bool:
	push_warning("Cannot call 'init_server_info_request' using LocalTransport")
	return false

func init_headless_server() -> bool:
	push_warning("Cannot call 'init_headless_server' using LocalTransport")
	return false
