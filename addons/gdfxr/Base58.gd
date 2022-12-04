extends Object

const BASE_58_ALPHABET := "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"


static func b58decode(v: String) -> StreamPeerBuffer:
	# Base 58 is a number expressed in the base-58 numeral system.
	# When encoding data, big-endian is used and leading zeros are encoded as leading `1`s.

	var original_length := v.length()
	v = v.lstrip(BASE_58_ALPHABET[0])
	var zeros := original_length - v.length()
	
	var buffer := PackedByteArray()
	buffer.resize(v.length())  # Won't be as long as base 58 string since the buffer is 256-based.
	buffer.fill(0)
	
	var length := 0
	for c in v:
		var carry := BASE_58_ALPHABET.find(c)
		if carry == -1:
			return null
		var i := 0
		while carry != 0 or i < length:
			var pos := buffer.size() - 1 - i
			carry += 58 * buffer[pos]
			buffer[pos] = carry % 256
			carry /= 256
			i += 1
		length = i
	
	var result := StreamPeerBuffer.new()
	for _i in zeros:
		result.put_8(0)
	result.put_data(buffer.slice(buffer.size() - length))
	result.seek(0)
	
	return result
