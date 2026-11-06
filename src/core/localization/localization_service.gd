class_name LocalizationService
extends RefCounted

## Dicionário estático para armazenar o último índice sorteado de cada chave base
## Garante que uma mesma fala ou bark nunca se repita duas vezes seguidas
static var _last_picked_variants: Dictionary = {}

## Retorna uma variante aleatória traduzida de uma chave base indexada (ex: base="BARK_TEA_EMPTY", count=4)
## Busca por chaves no formato BASE_KEY_1 até BASE_KEY_N
static func get_random_variant(base_key: String, count: int) -> String:
	if count <= 0:
		return ""
	if count == 1:
		return TranslationServer.translate(base_key + "_1")
	
	var last_idx: int = _last_picked_variants.get(base_key, -1)
	var available: Array[int] = []
	
	for i in range(1, count + 1):
		if i != last_idx:
			available.append(i)
	
	var chosen_idx: int = available.pick_random() if not available.is_empty() else 1
	_last_picked_variants[base_key] = chosen_idx
	
	var final_key: String = "%s_%d" % [base_key, chosen_idx]
	return TranslationServer.translate(final_key)

## Atalho semântico para tradução direta via TranslationServer nativo da Godot
static func get_text(key: String) -> String:
	return TranslationServer.translate(key)
