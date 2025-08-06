class_name EchoFunc extends Resource

enum CallerFlag {
	ANY = 0,
	SERVER_ONLY = 1,
	OWNER_ONLY = 2,
	SERVER_OR_OWNER = 3
}

@export var path: StringName
@export var parameters: Array[EchoVar.EncodingType]
@export var reliable: bool = true
@export var caller_flag := CallerFlag.ANY
