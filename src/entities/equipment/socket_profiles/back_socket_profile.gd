@tool
class_name BackSocketProfile
extends Resource

## Perfil global de ancoragem das costas / tronco frame a frame.
## Governa onde a arma de reserva (BackSocketWeapon) e o escudo (BackSocketShield) se posicionam
## acompanhando o tórax do personagem em cada frame.
##
## Dicas de edição:
## - X negativo: empurra para as costas (esquerda).
## - X positivo: aproxima do peito (direita).
## - Y negativo: SOBE em direção ao ombro/trapézio.
## - Y positivo: DESCE em direção à lombar/cinto.

@export_group("Identidade")
## Nome identificador.
@export var profile_name: String = "back_global"

@export_group("Idle (4 frames)")
## [Idle - Frame 0] (Em repouso / respiração em pé)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var idle_0_pos: Vector2 = Vector2(-3, -20)

## [Idle - Frame 1] (Em repouso / respiração em pé)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var idle_1_pos: Vector2 = Vector2(-3, -20)

## [Idle - Frame 2] (Em repouso / respiração em pé)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var idle_2_pos: Vector2 = Vector2(-3, -20)

## [Idle - Frame 3] (Em repouso / respiração em pé)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var idle_3_pos: Vector2 = Vector2(-3, -20)

@export_group("Run (6 frames)")
## [Run - Frame 0] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_0_pos: Vector2 = Vector2(-3, -20)

## [Run - Frame 1] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_1_pos: Vector2 = Vector2(-3, -20)

## [Run - Frame 2] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_2_pos: Vector2 = Vector2(-3, -20)

## [Run - Frame 3] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_3_pos: Vector2 = Vector2(-3, -20)

## [Run - Frame 4] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_4_pos: Vector2 = Vector2(-3, -20)

## [Run - Frame 5] (Corrida / deslocamento no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var run_5_pos: Vector2 = Vector2(-3, -20)

@export_group("Jump (4 frames)")
## [Jump - Frame 0] (Salto normal do chão (preparo, subida e ápice))
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var jump_0_pos: Vector2 = Vector2(-3, -20)

## [Jump - Frame 1] (Salto normal do chão (preparo, subida e ápice))
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var jump_1_pos: Vector2 = Vector2(-3, -20)

## [Jump - Frame 2] (Salto normal do chão (preparo, subida e ápice))
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var jump_2_pos: Vector2 = Vector2(-3, -20)

## [Jump - Frame 3] (Salto normal do chão (preparo, subida e ápice))
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var jump_3_pos: Vector2 = Vector2(-3, -20)

@export_group("Crouch (4 frames)")
## [Crouch - Frame 0] (Agachado / abaixado no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var crouch_0_pos: Vector2 = Vector2(-3, -20)

## [Crouch - Frame 1] (Agachado / abaixado no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var crouch_1_pos: Vector2 = Vector2(-3, -20)

## [Crouch - Frame 2] (Agachado / abaixado no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var crouch_2_pos: Vector2 = Vector2(-3, -20)

## [Crouch - Frame 3] (Agachado / abaixado no chão)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var crouch_3_pos: Vector2 = Vector2(-3, -20)

@export_group("Fall (2 frames)")
## [Fall - Frame 0] (Queda livre / descida)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var fall_0_pos: Vector2 = Vector2(-3, -20)

## [Fall - Frame 1] (Queda livre / descida)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var fall_1_pos: Vector2 = Vector2(-3, -20)

@export_group("FallFromJump (3 frames)")
## [FallFromJump - Frame 0] (Transição suave do ápice do pulo para a queda)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var fall_from_jump_0_pos: Vector2 = Vector2(-3, -20)

## [FallFromJump - Frame 1] (Transição suave do ápice do pulo para a queda)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var fall_from_jump_1_pos: Vector2 = Vector2(-3, -20)

## [FallFromJump - Frame 2] (Transição suave do ápice do pulo para a queda)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var fall_from_jump_2_pos: Vector2 = Vector2(-3, -20)

@export_group("Slide (2 frames)")
## [Slide - Frame 0] (Esquiva terrestre / rasteira sob vãos baixos)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var slide_0_pos: Vector2 = Vector2(-3, -20)

## [Slide - Frame 1] (Esquiva terrestre / rasteira sob vãos baixos)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var slide_1_pos: Vector2 = Vector2(-3, -20)

@export_group("Roll (4 frames)")
## [Roll - Frame 0] (Rolamento / mergulho giratório 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var roll_0_pos: Vector2 = Vector2(-3, -20)

## [Roll - Frame 1] (Rolamento / mergulho giratório 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var roll_1_pos: Vector2 = Vector2(-3, -20)

## [Roll - Frame 2] (Rolamento / mergulho giratório 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var roll_2_pos: Vector2 = Vector2(-3, -20)

## [Roll - Frame 3] (Rolamento / mergulho giratório 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var roll_3_pos: Vector2 = Vector2(-3, -20)

@export_group("DoubleJump (4 frames)")
## [DoubleJump - Frame 0] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var double_jump_0_pos: Vector2 = Vector2(-3, -20)

## [DoubleJump - Frame 1] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var double_jump_1_pos: Vector2 = Vector2(-3, -20)

## [DoubleJump - Frame 2] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var double_jump_2_pos: Vector2 = Vector2(-3, -20)

## [DoubleJump - Frame 3] (Pulo duplo aéreo / mortal acrobático 360°)
## Pos: X- costas, X+ peito, Y- ombro/sobe, Y+ lombar/desce.
@export var double_jump_3_pos: Vector2 = Vector2(-3, -20)

func get_frame_pos(anim_name: StringName, frame_idx: int) -> Vector2:
	var pos_prop := "%s_%d_pos" % [anim_name, frame_idx]
	if pos_prop in self:
		return get(pos_prop)
	return Vector2(-3, -20)
