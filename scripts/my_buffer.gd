# MyBuffer.gd
class_name MyBuffer
extends RefCounted

var BUFFER_U8 = 1
var BUFFER_U16 = 2
var BUFFER_U32 = 4
var BUFFER_U64 = 8

var data_array: PackedByteArray
var pos: int = 0


func _init(initial_data: PackedByteArray = PackedByteArray()):
	self.data_array = initial_data
	self.pos = 0

#=============================================================================
# MÉTODOS DE LEITURA (CORRIGIDOS)
#=============================================================================

func read_u8() -> int:
	if pos >= data_array.size():
		printerr("MyBuffer: Tentativa de ler u8 fora dos limites do buffer.")
		return 0
	
	#Para ler um único byte, acessamos o array pelo índice.
	var value = data_array[pos]
	pos += BUFFER_U8
	return value


func read_u16() -> int:
	if pos + 2 > data_array.size():
		printerr("MyBuffer: Tentativa de ler u16 fora dos limites do buffer.")
		return 0
		
	# CORREÇÃO: O método correto é decode_u16.
	var value = data_array.decode_u16(pos)
	pos += BUFFER_U16
	return value


func read_u32() -> int:
	if pos + 4 > data_array.size():
		printerr("MyBuffer: Tentativa de ler u32 fora dos limites do buffer.")
		return 0
		
	# CORREÇÃO: O método correto é decode_u32.
	var value = data_array.decode_u32(pos)
	pos += BUFFER_U32
	return value


func read_u64() -> int:
	if pos + 8 > data_array.size():
		printerr("MyBuffer: Tentativa de ler u64 fora dos limites do buffer.")
		return 0
		
	# CORREÇÃO: O método correto é decode_u64.
	var value = data_array.decode_u64(pos)
	pos += BUFFER_U64
	return value


func read_string() -> String:
	var end_pos = data_array.find(0, pos)
	
	if end_pos == -1:
		printerr("MyBuffer: Não foi encontrado um terminador nulo para a string.")
		# Se não encontrar, podemos decidir ler até o final
		end_pos = data_array.size()
	
	var string_bytes = PackedByteArray()
	string_bytes = data_array.slice(pos, end_pos)
	var text_decoded = string_bytes.get_string_from_utf8()
	
	# Avança a posição para depois do que foi lido (+1 para pular o byte nulo)
	pos = end_pos + 1
	
	return text_decoded


#=============================================================================
# MÉTODOS DE ESCRITA (sem alterações, já estavam corretos)
#=============================================================================

func write_u8(data: int):
	data_array.push_back(data)

func write_u16(data: int):
	# Esta forma de usar um array temporário e encode_* está correta.
	var bytes = PackedByteArray()
	bytes.resize(2) # Garante que o array tenha espaço
	bytes.encode_u16(0, data)
	data_array.append_array(bytes)

func write_u32(data: int):
	var bytes = PackedByteArray()
	bytes.resize(4)
	bytes.encode_u32(0, data)
	data_array.append_array(bytes)

func write_u64(data: int):
	var bytes = PackedByteArray()
	bytes.resize(8)
	bytes.encode_u64(0, data)
	data_array.append_array(bytes)

func write_string(data: String):
	data_array.append_array(data.to_utf8_buffer())
	data_array.push_back(0)


#=============================================================================
# MÉTODOS DE CONTROLE (sem alterações)
#=============================================================================

func seek_start():
	pos = 0

func seek(new_pos: int):
	if new_pos >= 0 and new_pos <= data_array.size():
		pos = new_pos
	else:
		printerr("MyBuffer: Posição de seek inválida: ", new_pos)

func clear():
	data_array.clear()
	pos = 0

func get_data_array() -> PackedByteArray:
	return data_array
