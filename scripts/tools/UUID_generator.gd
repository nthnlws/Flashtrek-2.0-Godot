extends RefCounted
class_name UUID

static func generate_UUID() -> String:
	# Generate 16 random bytes
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(16)
	for i in range(16):
		bytes[i] = randi() % 256
	
	# Set version to 4 (bits 4-7 of byte 6 to 0100)
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	# Set variant to RFC 4122 (bits 6-7 of byte 8 to 10)
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	
	# Format into standard 8-4-4-4-12 hex string
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		bytes[0], bytes[1], bytes[2], bytes[3],
		bytes[4], bytes[5],
		bytes[6], bytes[7],
		bytes[8], bytes[9],
		bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
	]
