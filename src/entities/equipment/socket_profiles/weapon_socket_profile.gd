@tool
class_name WeaponSocketProfile
extends Resource

## Perfil de ancoragem frame a frame para uma categoria ou variação de arma.
## Permite ajustar a posição, rotação e visibilidade da arma na mão do guerreiro.
##
## Dicas de edição:
## - X positivo: empurra a arma para a FRENTE (direita).
## - X negativo: puxa a arma para TRÁS (costas / esquerda).
## - Y negativo: SOBE a arma em direção ao ombro/cabeça.
## - Y positivo: DESCE a arma em direção ao chão.
## - Rotação: 0° aponta para a frente; valores negativos (-35°) inclinam para trás; +90° para baixo.

@export_group("Identidade do Perfil")
## Nome identificador deste perfil (ex: sword, sword_2, dagger, hammer).
@export var profile_name: String = "sword"

@export_group("Idle (4 frames)")
## [Idle - Frame 0] (Em repouso / respiração em pé)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var idle_0_pos: Vector2 = Vector2(6, -20)
## [Idle - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var idle_0_rot: float = -35.0
## [Idle - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var idle_0_visible: bool = true

## [Idle - Frame 1] (Em repouso / respiração em pé)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var idle_1_pos: Vector2 = Vector2(6, -20)
## [Idle - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var idle_1_rot: float = -35.0
## [Idle - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var idle_1_visible: bool = true

## [Idle - Frame 2] (Em repouso / respiração em pé)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var idle_2_pos: Vector2 = Vector2(6, -20)
## [Idle - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var idle_2_rot: float = -35.0
## [Idle - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var idle_2_visible: bool = true

## [Idle - Frame 3] (Em repouso / respiração em pé)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var idle_3_pos: Vector2 = Vector2(6, -20)
## [Idle - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var idle_3_rot: float = -35.0
## [Idle - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var idle_3_visible: bool = true

@export_group("Run (6 frames)")
## [Run - Frame 0] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_0_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_0_rot: float = -35.0
## [Run - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_0_visible: bool = true

## [Run - Frame 1] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_1_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_1_rot: float = -35.0
## [Run - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_1_visible: bool = true

## [Run - Frame 2] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_2_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_2_rot: float = -35.0
## [Run - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_2_visible: bool = true

## [Run - Frame 3] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_3_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_3_rot: float = -35.0
## [Run - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_3_visible: bool = true

## [Run - Frame 4] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_4_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 4] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_4_rot: float = -35.0
## [Run - Frame 4] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_4_visible: bool = true

## [Run - Frame 5] (Corrida / deslocamento no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var run_5_pos: Vector2 = Vector2(6, -20)
## [Run - Frame 5] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var run_5_rot: float = -35.0
## [Run - Frame 5] Visibilidade da arma (true = visível na mão, false = oculta).
@export var run_5_visible: bool = true

@export_group("Jump (4 frames)")
## [Jump - Frame 0] (Salto normal do chão (preparo, subida e ápice))
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var jump_0_pos: Vector2 = Vector2(6, -20)
## [Jump - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var jump_0_rot: float = -35.0
## [Jump - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var jump_0_visible: bool = true

## [Jump - Frame 1] (Salto normal do chão (preparo, subida e ápice))
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var jump_1_pos: Vector2 = Vector2(6, -20)
## [Jump - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var jump_1_rot: float = -35.0
## [Jump - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var jump_1_visible: bool = true

## [Jump - Frame 2] (Salto normal do chão (preparo, subida e ápice))
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var jump_2_pos: Vector2 = Vector2(6, -20)
## [Jump - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var jump_2_rot: float = -35.0
## [Jump - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var jump_2_visible: bool = true

## [Jump - Frame 3] (Salto normal do chão (preparo, subida e ápice))
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var jump_3_pos: Vector2 = Vector2(6, -20)
## [Jump - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var jump_3_rot: float = -35.0
## [Jump - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var jump_3_visible: bool = true

@export_group("Crouch (4 frames)")
## [Crouch - Frame 0] (Agachado / abaixado no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var crouch_0_pos: Vector2 = Vector2(6, -20)
## [Crouch - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var crouch_0_rot: float = -35.0
## [Crouch - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var crouch_0_visible: bool = true

## [Crouch - Frame 1] (Agachado / abaixado no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var crouch_1_pos: Vector2 = Vector2(6, -20)
## [Crouch - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var crouch_1_rot: float = -35.0
## [Crouch - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var crouch_1_visible: bool = true

## [Crouch - Frame 2] (Agachado / abaixado no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var crouch_2_pos: Vector2 = Vector2(6, -20)
## [Crouch - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var crouch_2_rot: float = -35.0
## [Crouch - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var crouch_2_visible: bool = true

## [Crouch - Frame 3] (Agachado / abaixado no chão)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var crouch_3_pos: Vector2 = Vector2(6, -20)
## [Crouch - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var crouch_3_rot: float = -35.0
## [Crouch - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var crouch_3_visible: bool = true

@export_group("Fall (2 frames)")
## [Fall - Frame 0] (Queda livre / descida)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var fall_0_pos: Vector2 = Vector2(6, -20)
## [Fall - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var fall_0_rot: float = -35.0
## [Fall - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var fall_0_visible: bool = true

## [Fall - Frame 1] (Queda livre / descida)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var fall_1_pos: Vector2 = Vector2(6, -20)
## [Fall - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var fall_1_rot: float = -35.0
## [Fall - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var fall_1_visible: bool = true

@export_group("FallFromJump (3 frames)")
## [FallFromJump - Frame 0] (Transição suave do ápice do pulo para a queda)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var fall_from_jump_0_pos: Vector2 = Vector2(6, -20)
## [FallFromJump - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var fall_from_jump_0_rot: float = -35.0
## [FallFromJump - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var fall_from_jump_0_visible: bool = true

## [FallFromJump - Frame 1] (Transição suave do ápice do pulo para a queda)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var fall_from_jump_1_pos: Vector2 = Vector2(6, -20)
## [FallFromJump - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var fall_from_jump_1_rot: float = -35.0
## [FallFromJump - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var fall_from_jump_1_visible: bool = true

## [FallFromJump - Frame 2] (Transição suave do ápice do pulo para a queda)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var fall_from_jump_2_pos: Vector2 = Vector2(6, -20)
## [FallFromJump - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var fall_from_jump_2_rot: float = -35.0
## [FallFromJump - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var fall_from_jump_2_visible: bool = true

@export_group("Slide (2 frames)")
## [Slide - Frame 0] (Esquiva terrestre / rasteira sob vãos baixos)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var slide_0_pos: Vector2 = Vector2(6, -20)
## [Slide - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var slide_0_rot: float = -35.0
## [Slide - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var slide_0_visible: bool = true

## [Slide - Frame 1] (Esquiva terrestre / rasteira sob vãos baixos)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var slide_1_pos: Vector2 = Vector2(6, -20)
## [Slide - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var slide_1_rot: float = -35.0
## [Slide - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var slide_1_visible: bool = true

@export_group("Roll (4 frames)")
## [Roll - Frame 0] (Rolamento / mergulho giratório 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var roll_0_pos: Vector2 = Vector2(6, -20)
## [Roll - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var roll_0_rot: float = -35.0
## [Roll - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var roll_0_visible: bool = true

## [Roll - Frame 1] (Rolamento / mergulho giratório 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var roll_1_pos: Vector2 = Vector2(6, -20)
## [Roll - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var roll_1_rot: float = -35.0
## [Roll - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var roll_1_visible: bool = true

## [Roll - Frame 2] (Rolamento / mergulho giratório 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var roll_2_pos: Vector2 = Vector2(6, -20)
## [Roll - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var roll_2_rot: float = -35.0
## [Roll - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var roll_2_visible: bool = true

## [Roll - Frame 3] (Rolamento / mergulho giratório 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var roll_3_pos: Vector2 = Vector2(6, -20)
## [Roll - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var roll_3_rot: float = -35.0
## [Roll - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var roll_3_visible: bool = true

@export_group("DoubleJump (4 frames)")
## [DoubleJump - Frame 0] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var double_jump_0_pos: Vector2 = Vector2(6, -20)
## [DoubleJump - Frame 0] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var double_jump_0_rot: float = -35.0
## [DoubleJump - Frame 0] Visibilidade da arma (true = visível na mão, false = oculta).
@export var double_jump_0_visible: bool = true

## [DoubleJump - Frame 1] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var double_jump_1_pos: Vector2 = Vector2(6, -20)
## [DoubleJump - Frame 1] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var double_jump_1_rot: float = -35.0
## [DoubleJump - Frame 1] Visibilidade da arma (true = visível na mão, false = oculta).
@export var double_jump_1_visible: bool = true

## [DoubleJump - Frame 2] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var double_jump_2_pos: Vector2 = Vector2(6, -20)
## [DoubleJump - Frame 2] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var double_jump_2_rot: float = -35.0
## [DoubleJump - Frame 2] Visibilidade da arma (true = visível na mão, false = oculta).
@export var double_jump_2_visible: bool = true

## [DoubleJump - Frame 3] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X+ empurra p/ FRENTE, X- puxa p/ TRÁS, Y- SOBE p/ ombro, Y+ DESCE p/ chão.
@export var double_jump_3_pos: Vector2 = Vector2(6, -20)
## [DoubleJump - Frame 3] Rotação em graus (0° = frente horizontal, -35° = repouso inclinado para trás).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var double_jump_3_rot: float = -35.0
## [DoubleJump - Frame 3] Visibilidade da arma (true = visível na mão, false = oculta).
@export var double_jump_3_visible: bool = true

@export_group("Costas (Configuração Base & Frames)")
## Posição padrão da arma nas costas quando o frame específico não foi calibrado.
@export var default_back_pos: Vector2 = Vector2(-6, -24)
## Rotação padrão da arma nas costas em graus (ex: -175° para arco, 225° para espada).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var default_back_rot: float = -175.0
## Dados calibrados frame a frame nas costas: {"idle_0": {"pos": Vector2, "rot": float, "visible": bool}, ...}
@export var back_frames: Dictionary = {}

func get_frame_data(anim_name: StringName, frame_idx: int) -> Dictionary:
	var pos_prop := "%s_%d_pos" % [anim_name, frame_idx]
	if pos_prop in self:
		var rot_prop := "%s_%d_rot" % [anim_name, frame_idx]
		var vis_prop := "%s_%d_visible" % [anim_name, frame_idx]
		return {
			"pos": get(pos_prop),
			"rot": get(rot_prop),
			"visible": get(vis_prop)
		}
	return {"pos": Vector2(6, -20), "rot": -35.0, "visible": true}

func get_back_frame_data(anim_name: StringName, frame_idx: int) -> Dictionary:
	var key := "%s_%d" % [anim_name, frame_idx]
	if back_frames.has(key):
		var data = back_frames[key]
		if data is Dictionary:
			return {
				"pos": data.get("pos", default_back_pos),
				"rot": data.get("rot", default_back_rot),
				"visible": data.get("visible", true)
			}
	return {
		"pos": default_back_pos,
		"rot": default_back_rot,
		"visible": true
	}

func set_back_frame_data(anim_name: StringName, frame_idx: int, pos: Vector2, rot: float, vis: bool = true) -> void:
	var key := "%s_%d" % [anim_name, frame_idx]
	back_frames[key] = {
		"pos": pos,
		"rot": rot,
		"visible": vis
	}

