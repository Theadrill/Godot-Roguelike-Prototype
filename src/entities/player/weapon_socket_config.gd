class_name WeaponSocketConfig
extends RefCounted

## Configuração de ancoragem frame a frame do MainHandSocket para cada categoria de arma.
## 
## Como editar no Godot:
## 1. Abra este arquivo na aba Script do Godot.
## 2. Procure a categoria desejada ("sword", "dagger", "hammer", "staff", "bow", "crossbow").
## 3. Em cada animação, ajuste:
##    - "pos": Vector2(x, y) -> Posição da mão/punho relativa ao personagem (origem dos pés em 0, 0).
##    - "rot": Rotação em graus (ex: -35.0 inclina a lâmina para trás; 0.0 aponta para a frente).
##    - "visible": true ou false (se false, oculta a arma naquele frame específico, ex: durante um rolamento).

const OFFSETS: Dictionary = {
	"sword": {
		&"idle": [
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 3
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 4
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(6, -20), "rot": -35.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -45.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -24), "rot": -50.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(6, -12), "rot": -35.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -12), "rot": -35.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -12), "rot": -35.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -12), "rot": -35.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(6, -22), "rot": -30.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -30.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(6, -24), "rot": -40.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -30.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -22), "rot": -30.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(8, -8), "rot": -10.0, "visible": true}, # Frame 0
			{"pos": Vector2(8, -8), "rot": -10.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(4, -14), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -18), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -14), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -18), "rot": 0.0, "visible": true},    # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(4, -14), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -18), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -14), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -18), "rot": 0.0, "visible": true},    # Frame 3
		],
	},

	"dagger": {
		&"idle": [
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 1
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 2
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 1
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 2
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 3
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 4
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(5, -18), "rot": -20.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -20), "rot": -30.0, "visible": true}, # Frame 1
			{"pos": Vector2(5, -22), "rot": -35.0, "visible": true}, # Frame 2
			{"pos": Vector2(5, -20), "rot": -25.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(5, -10), "rot": -20.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -10), "rot": -20.0, "visible": true}, # Frame 1
			{"pos": Vector2(5, -10), "rot": -20.0, "visible": true}, # Frame 2
			{"pos": Vector2(5, -10), "rot": -20.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(5, -20), "rot": -15.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -20), "rot": -15.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(5, -22), "rot": -25.0, "visible": true}, # Frame 0
			{"pos": Vector2(5, -20), "rot": -15.0, "visible": true}, # Frame 1
			{"pos": Vector2(5, -20), "rot": -15.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(7, -7), "rot": -5.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -7), "rot": -5.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(3, -12), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -16), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-3, -12), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(3, -16), "rot": 0.0, "visible": true},    # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(3, -12), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -16), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-3, -12), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(3, -16), "rot": 0.0, "visible": true},    # Frame 3
		],
	},

	"hammer": {
		&"idle": [
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 1
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 2
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 1
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 2
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 3
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 4
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(7, -22), "rot": -50.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -24), "rot": -60.0, "visible": true}, # Frame 1
			{"pos": Vector2(7, -26), "rot": -65.0, "visible": true}, # Frame 2
			{"pos": Vector2(7, -24), "rot": -55.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(7, -14), "rot": -50.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -14), "rot": -50.0, "visible": true}, # Frame 1
			{"pos": Vector2(7, -14), "rot": -50.0, "visible": true}, # Frame 2
			{"pos": Vector2(7, -14), "rot": -50.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(7, -24), "rot": -45.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -24), "rot": -45.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(7, -26), "rot": -55.0, "visible": true}, # Frame 0
			{"pos": Vector2(7, -24), "rot": -45.0, "visible": true}, # Frame 1
			{"pos": Vector2(7, -24), "rot": -45.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(9, -10), "rot": -20.0, "visible": true}, # Frame 0
			{"pos": Vector2(9, -10), "rot": -20.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(5, -16), "rot": -100.0, "visible": true}, # Frame 0
			{"pos": Vector2(0, -20), "rot": -190.0, "visible": true}, # Frame 1
			{"pos": Vector2(-5, -16), "rot": -280.0, "visible": true},# Frame 2
			{"pos": Vector2(5, -20), "rot": -10.0, "visible": true},  # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(5, -16), "rot": -100.0, "visible": true}, # Frame 0
			{"pos": Vector2(0, -20), "rot": -190.0, "visible": true}, # Frame 1
			{"pos": Vector2(-5, -16), "rot": -280.0, "visible": true},# Frame 2
			{"pos": Vector2(5, -20), "rot": -10.0, "visible": true},  # Frame 3
		],
	},

	"staff": {
		&"idle": [
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 3
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 4
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(6, -22), "rot": -40.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -24), "rot": -50.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -26), "rot": -55.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -24), "rot": -45.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(6, -14), "rot": -40.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -14), "rot": -40.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -14), "rot": -40.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -14), "rot": -40.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(6, -24), "rot": -35.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -24), "rot": -35.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(6, -26), "rot": -45.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -24), "rot": -35.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -24), "rot": -35.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(8, -10), "rot": -15.0, "visible": true}, # Frame 0
			{"pos": Vector2(8, -10), "rot": -15.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(4, -15), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -19), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -15), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -19), "rot": 0.0, "visible": true},    # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(4, -15), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -19), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -15), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -19), "rot": 0.0, "visible": true},    # Frame 3
		],
	},

	"bow": {
		&"idle": [
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 3
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 4
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(6, -20), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": -10.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -24), "rot": -15.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -22), "rot": -5.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(6, -12), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -12), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -12), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -12), "rot": 0.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(6, -22), "rot": 5.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": 5.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(6, -24), "rot": -5.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -22), "rot": 5.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -22), "rot": 5.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(8, -8), "rot": 15.0, "visible": true}, # Frame 0
			{"pos": Vector2(8, -8), "rot": 15.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(4, -14), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -18), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -14), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -18), "rot": 0.0, "visible": true},    # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(4, -14), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -18), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -14), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -18), "rot": 0.0, "visible": true},    # Frame 3
		],
	},

	"crossbow": {
		&"idle": [
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 3
		],
		&"run": [
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 3
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 4
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 5
		],
		&"jump": [
			{"pos": Vector2(6, -18), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": -10.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -22), "rot": -15.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -20), "rot": -5.0, "visible": true}, # Frame 3
		],
		&"crouch": [
			{"pos": Vector2(6, -10), "rot": 0.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -10), "rot": 0.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -10), "rot": 0.0, "visible": true}, # Frame 2
			{"pos": Vector2(6, -10), "rot": 0.0, "visible": true}, # Frame 3
		],
		&"fall": [
			{"pos": Vector2(6, -20), "rot": 5.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": 5.0, "visible": true}, # Frame 1
		],
		&"fall_from_jump": [
			{"pos": Vector2(6, -22), "rot": -5.0, "visible": true}, # Frame 0
			{"pos": Vector2(6, -20), "rot": 5.0, "visible": true}, # Frame 1
			{"pos": Vector2(6, -20), "rot": 5.0, "visible": true}, # Frame 2
		],
		&"slide": [
			{"pos": Vector2(8, -6), "rot": 10.0, "visible": true}, # Frame 0
			{"pos": Vector2(8, -6), "rot": 10.0, "visible": true}, # Frame 1
		],
		&"roll": [
			{"pos": Vector2(4, -12), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -16), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -12), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -16), "rot": 0.0, "visible": true},    # Frame 3
		],
		&"double_jump": [
			{"pos": Vector2(4, -12), "rot": -90.0, "visible": true},  # Frame 0
			{"pos": Vector2(0, -16), "rot": -180.0, "visible": true}, # Frame 1
			{"pos": Vector2(-4, -12), "rot": -270.0, "visible": true},# Frame 2
			{"pos": Vector2(4, -16), "rot": 0.0, "visible": true},    # Frame 3
		],
	},
}

static func get_socket_data(category: String, anim_name: StringName, frame_idx: int) -> Dictionary:
	var cat_data: Dictionary = OFFSETS.get(category, OFFSETS.get("sword", {}))
	if cat_data.has(anim_name):
		var frames: Array = cat_data[anim_name]
		if frame_idx >= 0 and frame_idx < frames.size():
			return frames[frame_idx]
	# Fallback padrão seguro
	return {"pos": Vector2(6, -20), "rot": -35.0, "visible": true}
