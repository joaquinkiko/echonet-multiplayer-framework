## Represents a variant to be syncronized over the network
class_name EchoVar extends Resource

## Encoding type to use for data
enum EncodingType {
	VARIANT,
	I_U8,
	I_U16,
	I_U32,
	I_U64,
	I_S8 ,
	I_S16,
	I_S32,
	I_S64,
	F_16,
	F_32,
	F_64,
	VECTOR2_F16,
	VECTOR2_F32,
	VECTOR2_F64,
	VECTOR3_F16,
	VECTOR3_F32,
	VECTOR3_F64,
	VECTOR2I_U8,
	VECTOR2I_U16,
	VECTOR2I_U32,
	VECTOR2I_U64,
	VECTOR2I_S8,
	VECTOR2I_S16,
	VECTOR2I_S32,
	VECTOR2I_S64,
	VECTOR3I_U8,
	VECTOR3I_U16,
	VECTOR3I_U32,
	VECTOR3I_U64,
	VECTOR3I_S8,
	VECTOR3I_S16,
	VECTOR3I_S32,
	VECTOR3I_S64,
	BOOL,
	ASCII_CHARS,
	PACKED_BYTE_ARRAY,
}

## [NodePath] to parameter to syncronize
@export var path: StringName
## Encoding type to use for parameter
@export var encoding_type := EncodingType.VARIANT

@export var owner_authoritative: bool

## Static method to encode value based on [EncodingType]
static func encode_var(encoding: EncodingType, value: Variant) -> PackedByteArray:
	var data: PackedByteArray
	match encoding:
		EncodingType.I_U8:
			data.resize(1)
			data.encode_u8(0, int(value))
		EncodingType.I_U16:
			data.resize(2)
			data.encode_u16(0, int(value))
		EncodingType.I_U32:
			data.resize(4)
			data.encode_u32(0, int(value))
		EncodingType.I_U64:
			data.resize(8)
			data.encode_u64(0, int(value))
		EncodingType.I_S8:
			data.resize(1)
			data.encode_s8(0, int(value))
		EncodingType.I_S16:
			data.resize(2)
			data.encode_s16(0, int(value))
		EncodingType.I_S32:
			data.resize(4)
			data.encode_s32(0, int(value))
		EncodingType.I_S64:
			data.resize(8)
			data.encode_s64(0, int(value))
		EncodingType.F_16:
			data.resize(2)
			data.encode_half(0, float(value))
		EncodingType.F_32:
			data.resize(4)
			data.encode_float(0, float(value))
		EncodingType.F_64:
			data.resize(8)
			data.encode_double(0, float(value))
		EncodingType.BOOL:
			data.resize(1)
			data.encode_u8(0, bool(value))
		EncodingType.ASCII_CHARS:
			data.resize(2)
			data.encode_u16(0, String(value).length())
			data.append_array(String(value).to_ascii_buffer())
		EncodingType.PACKED_BYTE_ARRAY:
			data.resize(2)
			if value is PackedByteArray:
				data.encode_u16(0, value.size())
				data.append_array(value)
			else:
				var value_raw: PackedByteArray
				value_raw.resize(256)
				value_raw.encode_var(0, value)
				value_raw.resize(data.decode_var_size(0))
				data.encode_u16(0, value_raw.size())
				data.append_array(value_raw)
		EncodingType.VECTOR2_F16:
			data.resize(2*2)
			data.encode_half(0, Vector2(value).x)
			data.encode_half(2, Vector2(value).y)
		EncodingType.VECTOR2_F32:
			data.resize(4*2)
			data.encode_float(0, Vector2(value).x)
			data.encode_float(4, Vector2(value).y)
		EncodingType.VECTOR2_F64:
			data.resize(8*2)
			data.encode_double(0, Vector2(value).x)
			data.encode_double(8, Vector2(value).y)
		EncodingType.VECTOR3_F16:
			data.resize(2*3)
			data.encode_half(0, Vector3(value).x)
			data.encode_half(2, Vector3(value).y)
			data.encode_half(4, Vector3(value).z)
		EncodingType.VECTOR3_F32:
			data.resize(4*3)
			data.encode_float(0, Vector3(value).x)
			data.encode_float(4, Vector3(value).y)
			data.encode_float(8, Vector3(value).z)
		EncodingType.VECTOR3_F64:
			data.resize(8*3)
			data.encode_double(0, Vector3(value).x)
			data.encode_double(8, Vector3(value).y)
			data.encode_double(16, Vector3(value).z)
		EncodingType.VECTOR2I_U8:
			data.resize(1*2)
			data.encode_u8(0, Vector2i(value).x)
			data.encode_u8(1, Vector2i(value).y)
		EncodingType.VECTOR2I_U16:
			data.resize(2*2)
			data.encode_u16(0, Vector2i(value).x)
			data.encode_u16(2, Vector2i(value).y)
		EncodingType.VECTOR2I_U32:
			data.resize(4*2)
			data.encode_u32(0, Vector2i(value).x)
			data.encode_u32(4, Vector2i(value).y)
		EncodingType.VECTOR2I_U64:
			data.resize(8*2)
			data.encode_u64(0, Vector2i(value).x)
			data.encode_u64(8, Vector2i(value).y)
		EncodingType.VECTOR2I_S8:
			data.resize(1*2)
			data.encode_s8(0, Vector2i(value).x)
			data.encode_s8(1, Vector2i(value).y)
		EncodingType.VECTOR2I_S16:
			data.resize(2*2)
			data.encode_s16(0, Vector2i(value).x)
			data.encode_s16(2, Vector2i(value).y)
		EncodingType.VECTOR2I_S32:
			data.resize(4*2)
			data.encode_s32(0, Vector2i(value).x)
			data.encode_s32(4, Vector2i(value).y)
		EncodingType.VECTOR2I_S64:
			data.resize(8*2)
			data.encode_s64(0, Vector2i(value).x)
			data.encode_s64(8, Vector2i(value).y)
		EncodingType.VECTOR3I_U8:
			data.resize(1*3)
			data.encode_u8(0, Vector3i(value).x)
			data.encode_u8(1, Vector3i(value).y)
			data.encode_u8(2, Vector3i(value).z)
		EncodingType.VECTOR3I_U16:
			data.resize(2*3)
			data.encode_u16(0, Vector3i(value).x)
			data.encode_u16(2, Vector3i(value).y)
			data.encode_u16(4, Vector3i(value).z)
		EncodingType.VECTOR3I_U32:
			data.resize(4*3)
			data.encode_u32(0, Vector3i(value).x)
			data.encode_u32(4, Vector3i(value).y)
			data.encode_u32(8, Vector3i(value).z)
		EncodingType.VECTOR3I_U64:
			data.resize(8*3)
			data.encode_u64(0, Vector3i(value).x)
			data.encode_u64(8, Vector3i(value).y)
			data.encode_u64(16, Vector3i(value).z)
		EncodingType.VECTOR3I_S8:
			data.resize(1*3)
			data.encode_s8(0, Vector3i(value).x)
			data.encode_s8(1, Vector3i(value).y)
			data.encode_s8(2, Vector3i(value).z)
		EncodingType.VECTOR3I_S16:
			data.resize(2*3)
			data.encode_s16(0, Vector3i(value).x)
			data.encode_s16(2, Vector3i(value).y)
			data.encode_s16(4, Vector3i(value).z)
		EncodingType.VECTOR3I_S32:
			data.resize(4*3)
			data.encode_s32(0, Vector3i(value).x)
			data.encode_s32(4, Vector3i(value).y)
			data.encode_s32(8, Vector3i(value).z)
		EncodingType.VECTOR3I_S64:
			data.resize(8*3)
			data.encode_s64(0, Vector3i(value).x)
			data.encode_s64(8, Vector3i(value).y)
			data.encode_s64(16, Vector3i(value).z)
		_:
			data.resize(256)
			data.encode_var(0, value)
			data.resize(data.decode_var_size(0))
	return data

## Static method to decode value based on [EncodingType]
static func decode_var(encoding: EncodingType, data: PackedByteArray) -> Variant:
	match encoding:
		EncodingType.I_U8:
			return data.decode_u8(0)
		EncodingType.I_U16:
			return data.decode_u16(0)
		EncodingType.I_U32:
			return data.decode_u32(0)
		EncodingType.I_U64:
			return data.decode_u64(0)
		EncodingType.I_S8:
			return data.decode_s8(0)
		EncodingType.I_S16:
			return data.decode_s16(0)
		EncodingType.I_S32:
			return data.decode_s32(0)
		EncodingType.I_S64:
			return data.decode_s64(0)
		EncodingType.F_16:
			return data.decode_half(0)
		EncodingType.F_32:
			return data.decode_float(0)
		EncodingType.F_64:
			return data.decode_double(0)
		EncodingType.BOOL:
			return bool(data.decode_u8(0))
		EncodingType.ASCII_CHARS:
			return data.slice(2, data.decode_u16(0) + 2).get_string_from_ascii()
		EncodingType.PACKED_BYTE_ARRAY:
			return data.slice(2, data.decode_u16(0) + 2)
		EncodingType.VECTOR2_F16:
			return Vector2(data.decode_half(0), data.decode_half(2))
		EncodingType.VECTOR2_F32:
			return Vector2(data.decode_float(0), data.decode_float(4))
		EncodingType.VECTOR2_F64:
			return Vector2(data.decode_double(0), data.decode_double(8))
		EncodingType.VECTOR3_F16:
			return Vector3(data.decode_half(0), data.decode_half(2), data.decode_half(4))
		EncodingType.VECTOR3_F32:
			return Vector3(data.decode_float(0), data.decode_float(4), data.decode_float(8))
		EncodingType.VECTOR3_F64:
			return Vector3(data.decode_double(0), data.decode_double(8), data.decode_double(16))
		EncodingType.VECTOR2I_U8:
			return Vector2i(data.decode_u8(0), data.decode_u8(1))
		EncodingType.VECTOR2I_U16:
			return Vector2i(data.decode_u16(0), data.decode_u16(2))
		EncodingType.VECTOR2I_U32:
			return Vector2i(data.decode_u32(0), data.decode_u32(4))
		EncodingType.VECTOR2I_U64:
			return Vector2i(data.decode_u64(0), data.decode_u64(8))
		EncodingType.VECTOR2I_S8:
			return Vector2i(data.decode_s8(0), data.decode_s8(1))
		EncodingType.VECTOR2I_S16:
			return Vector2i(data.decode_s16(0), data.decode_s16(2))
		EncodingType.VECTOR2I_S32:
			return Vector2i(data.decode_s32(0), data.decode_s32(4))
		EncodingType.VECTOR2I_S64:
			return Vector2i(data.decode_s64(0), data.decode_s64(8))
		EncodingType.VECTOR3I_U8:
			return Vector3i(data.decode_u8(0), data.decode_u8(1), data.decode_u8(2))
		EncodingType.VECTOR3I_U16:
			return Vector3i(data.decode_u16(0), data.decode_u16(2), data.decode_u16(4))
		EncodingType.VECTOR3I_U32:
			return Vector3i(data.decode_u32(0), data.decode_u32(4), data.decode_u32(8))
		EncodingType.VECTOR3I_U64:
			return Vector3i(data.decode_u64(0), data.decode_u64(8), data.decode_u64(16))
		EncodingType.VECTOR3I_S8:
			return Vector3i(data.decode_s8(0), data.decode_s8(1), data.decode_s8(2))
		EncodingType.VECTOR3I_S16:
			return Vector3i(data.decode_s16(0), data.decode_s16(2), data.decode_s16(4))
		EncodingType.VECTOR3I_S32:
			return Vector3i(data.decode_s32(0), data.decode_s32(4), data.decode_s32(8))
		EncodingType.VECTOR3I_S64:
			return Vector3i(data.decode_s64(0), data.decode_s64(8), data.decode_s64(16))
		_:
			return data.decode_var(0)

## Static method to determine size of [EncodingType].
## Note: [EncodingType.VARIANT],[EncodingType.ASCII_CHARS], and [EncodingType.PACKED_BYTE_ARRAY]
## have variable sizes, and must have the source data passed in as well to determine size.
static func get_var_size(encoding: EncodingType, data: PackedByteArray = []) -> int:
	match encoding:
		EncodingType.I_U8:
			return 1
		EncodingType.I_U16:
			return 2
		EncodingType.I_U32:
			return 4
		EncodingType.I_U64:
			return 8
		EncodingType.I_S8:
			return 1
		EncodingType.I_S16:
			return 2
		EncodingType.I_S32:
			return 4
		EncodingType.I_S64:
			return 8
		EncodingType.F_16:
			return 2
		EncodingType.F_32:
			return 4
		EncodingType.F_64:
			return 8
		EncodingType.BOOL:
			return 1
		EncodingType.ASCII_CHARS:
			if data.size() < 2: return data.size()
			return data.decode_u16(0) + 2
		EncodingType.PACKED_BYTE_ARRAY:
			if data.size() < 2: return data.size()
			return data.decode_u16(0) + 2
		EncodingType.VECTOR2_F16:
			return 2*2
		EncodingType.VECTOR2_F32:
			return 4*2
		EncodingType.VECTOR2_F64:
			return 8*2
		EncodingType.VECTOR3_F16:
			return 2*3
		EncodingType.VECTOR3_F32:
			return 4*3
		EncodingType.VECTOR3_F64:
			return 8*3
		EncodingType.VECTOR2I_U8:
			return 1*2
		EncodingType.VECTOR2I_U16:
			return 2*2
		EncodingType.VECTOR2I_U32:
			return 4*2
		EncodingType.VECTOR2I_U64:
			return 8*2
		EncodingType.VECTOR2I_S8:
			return 1*2
		EncodingType.VECTOR2I_S16:
			return 2*2
		EncodingType.VECTOR2I_S32:
			return 4*2
		EncodingType.VECTOR2I_S64:
			return 8*2
		EncodingType.VECTOR3I_U8:
			return 1*3
		EncodingType.VECTOR3I_U16:
			return 2*3
		EncodingType.VECTOR3I_U32:
			return 4*3
		EncodingType.VECTOR3I_U64:
			return 8*3
		EncodingType.VECTOR3I_S8:
			return 1*3
		EncodingType.VECTOR3I_S16:
			return 2*3
		EncodingType.VECTOR3I_S32:
			return 4*3
		EncodingType.VECTOR3I_S64:
			return 8*3
		_:
			if data.size() < 4: return data.size()
			return data.decode_var_size(0)

## Returns true if [member path] is a valid [NodePath]
func is_valid_path(source: Node) -> bool:
	return source.has_node(NodePath(path))

func get_var(source: Node) -> Variant:
	if !is_valid_path(source):
		push_warning("EchoVar attempting to access invalid path: %s"%path)
		return null
	return source.get_node(NodePath(path)).get_indexed(NodePath(NodePath(path).get_concatenated_subnames()).get_as_property_path())

func set_var(source: Node, value: Variant) -> void:
	if owner_authoritative && source.parent_echo_scene.owner.is_self: return
	if !is_valid_path(source):
		push_warning("EchoVar attempting to set invalid path: %s"%path)
		return
	source.get_node(NodePath(path)).set_indexed(NodePath(NodePath(path).get_concatenated_subnames()).get_as_property_path(), value)

func get_var_encoded(source: Node) -> PackedByteArray:
	return encode_var(encoding_type, get_var(source))

func set_var_encoded(source: Node, data: PackedByteArray) -> void:
	set_var(source, decode_var(encoding_type, data))

static func get_base_encoded(encoding: EncodingType) -> PackedByteArray:
	match encoding:
		EncodingType.I_U8:
			return encode_var(encoding, 0)
		EncodingType.I_U16:
			return encode_var(encoding, 0)
		EncodingType.I_U32:
			return encode_var(encoding, 0)
		EncodingType.I_U64:
			return encode_var(encoding, 0)
		EncodingType.I_S8:
			return encode_var(encoding, 0)
		EncodingType.I_S16:
			return encode_var(encoding, 0)
		EncodingType.I_S32:
			return encode_var(encoding, 0)
		EncodingType.I_S64:
			return encode_var(encoding, 0)
		EncodingType.F_16:
			return encode_var(encoding, 0)
		EncodingType.F_32:
			return encode_var(encoding, 0)
		EncodingType.F_64:
			return encode_var(encoding, 0)
		EncodingType.BOOL:
			return encode_var(encoding, false)
		EncodingType.ASCII_CHARS:
			return encode_var(encoding, "")
		EncodingType.PACKED_BYTE_ARRAY:
			return encode_var(encoding, [])
		EncodingType.VECTOR2_F16:
			return encode_var(encoding, Vector2(0,0))
		EncodingType.VECTOR2_F32:
			return encode_var(encoding, Vector2(0,0))
		EncodingType.VECTOR2_F64:
			return encode_var(encoding, Vector2(0,0))
		EncodingType.VECTOR3_F16:
			return encode_var(encoding, Vector3(0,0,0))
		EncodingType.VECTOR3_F32:
			return encode_var(encoding, Vector3(0,0,0))
		EncodingType.VECTOR3_F64:
			return encode_var(encoding, Vector3(0,0,0))
		EncodingType.VECTOR2I_U8:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_U16:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_U32:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_U64:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_S8:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_S16:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_S32:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR2I_S64:
			return encode_var(encoding, Vector2i(0,0))
		EncodingType.VECTOR3I_U8:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_U16:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_U32:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_U64:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_S8:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_S16:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_S32:
			return encode_var(encoding, Vector3i(0,0,0))
		EncodingType.VECTOR3I_S64:
			return encode_var(encoding, Vector3i(0,0,0))
		_:
			return encode_var(encoding, null)
