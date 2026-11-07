class_name EnemyCategories
extends RefCounted

## Classificação oficial de tipos de criaturas de Severed Dawn.
## Permite ao PO configurar facilmente a categoria de qualquer inimigo no Inspector do Godot
## e alimenta os marcos de desbloqueio dos pedestais e rastreio de almas da linhagem.

enum Category {
	UNDEAD,      ## Zumbis, esqueletos e carcaças reerguidas pela anomalia
	BEAST,       ## Feras da floresta corrompidas (lobos, morcegos gigantes, javalis)
	ABOMINATION, ## Amálgamas grotescas e manifestações puras da Ruína
	HUMANOID,    ## Soldados imperiais, guardas corrompidos e saqueadores
	BOSS         ## Portadores do Caos (Guardiões dos selos temporais)
}

static func get_category_name(cat: Category) -> String:
	match cat:
		Category.UNDEAD:
			return "Morto-Vivo"
		Category.BEAST:
			return "Besta"
		Category.ABOMINATION:
			return "Abominação"
		Category.HUMANOID:
			return "Humanoide"
		Category.BOSS:
			return "Portador do Caos"
		_:
			return "Desconhecido"
