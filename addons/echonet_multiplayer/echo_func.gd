## Reprsents a function that can be called via remote procedure call over the network
class_name EchoFunc extends Resource

## Flags for who can call an [EchoFunc]
enum CallerFlag {
	ANY = 0,
	SERVER_ONLY = 1,
	OWNER_ONLY = 2,
	SERVER_OR_OWNER = 3
}

## Path to Node to call function on
@export var path: NodePath
## Function to call
@export var method: StringName
## Number of parameters, and [EchoVar.EncodingType] type to be used for each method parameter
@export var parameters: Array[EchoVar.EncodingType]
## True if method should be sent reliably
@export var reliable: bool = true
## Determines who is allowed to call this method
@export var caller_flag := CallerFlag.ANY

## Used to call method locally
func remote_call(args: Array, echo_node: EchoNode) -> Variant:
	var node := echo_node.get_node(NodePath(path))
	assert(node != null, "NodePath '%s' not found for locally called method"%[NodePath(path)])
	assert(node.has_method(method), "Locally called method '%s' not found in %s"%[method, node])
	return node.callv(method, args)

## Used to process external request for method
func receive_remote_call(args_data: PackedByteArray, echo_node: EchoNode, caller: EchonetPeer) -> void:
	var node := echo_node.get_node(NodePath(path))
	assert(node != null, "NodePath '%s' not found for remotely called method"%[NodePath(path)])
	assert(node.has_method(method), "Remotely called method '%s' not found in %s"%[method, node])
	var args := decode_args(args_data)
	node.callv(method, args)

## Encodes method arguments to [PackedByteArray]
func encode_args(args: Array) -> PackedByteArray:
	var data: PackedByteArray
	args.resize(parameters.size())
	for n in parameters.size():
		data.append_array(EchoVar.encode_var(parameters[n], args[n]))
	return data

## Decodes method arguments from a [PackedByteArray]
func decode_args(data: PackedByteArray) -> Array:
	var output: Array
	output.resize(parameters.size())
	for n in parameters.size():
		if data.size() < EchoVar.get_var_size(parameters[n], data): break
		output[n] = EchoVar.decode_var(parameters[n], data)
		data = data.slice(EchoVar.get_var_size(parameters[n], data))
	return output
