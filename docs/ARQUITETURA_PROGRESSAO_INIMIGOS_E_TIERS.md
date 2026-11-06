# Arquitetura de Inimigos, Progressão e Sistema de Tiers Dinâmicos

> [!IMPORTANT]
> **Documento Oficial de Arquitetura de IA e Progressão de Inimigos — Severed Dawn**
> Todas as classes de inimigos presentes e futuras (`Soldier`, `Archer`, `Mage`, chefes e subchefes) devem seguir rigorosamente os padrões definidos neste documento.

---

## 1. Filosofia de Combate e Ritmo (Cadência e Peso)

1. **Ataques Significativos (High-Stakes):**
   * O combate de *Severed Dawn* prioriza intenção, precisão e leitura tática. Os inimigos atacam de forma cadenciada com **cooldowns substanciais (2.0s a 20.0s)**, onde cada golpe possui perigo real.
2. **Movimentação Ativa Durante o Cooldown (Fim do "Inimigo Manequim"):**
   * Em vez de ficarem paralisados após golpear, os inimigos se movimentam com atitude durante o período de recuperação:
     * **`AGGRESSIVE_STALK`:** Caminhada cadenciada, pesada e ameaçadora (~40-50% vel.) na direção do jogador, encurralando-o para que no fim do cooldown o próximo golpe seja imediato.
     * **`DEFENSIVE_RETREAT`:** Recuo tático com passos para trás (*footsies* / *kiting*), mantendo distância de segurança sem cair de penhascos.
     * **`STAND_GROUND`:** Permanece plantado no lugar com guarda erguida (indicado para inimigos pesados, escudeiros e sentinelas).
     * **`ADAPTIVE` (Duelistas / Assassinos Ágeis):** Avança com agressividade, mas **se o jogador bloquear com o escudo ou aplicar Parry**, a IA reconhece o risco, recua com esquiva tática para trás, ganha espaço de respiro e reengaja em seguida (buscando ataques pesados ou indefensáveis para quebrar a guarda).
3. **Entidades Imóveis (`can_move`) e Resistência Física (`takes_knockback`):**
   * Permite criar mãos de boss gigante, plantas carnívoras e torretas sentinelas que:
     * Nunca se deslocam nem dão passos à frente ao atacar.
     * Ignoram repulsão e empurrões físicos (`knockback = Vector2.ZERO`).

---

## 2. A Progressão Dinâmica por Nível (Sem Gatekeeping)

### A Crítica ao Modelo Tradicional
Em jogos como *Dead Cells* e *Nine Sols*, grande parte das mecânicas avançadas e inteligência de elite só é experienciada após zerar o jogo completo (Boss Cells / NG+). Como mais de 75% dos jogadores abandonam os títulos antes do chefe final, esse modelo priva a maioria da melhor experiência do jogo.

### A Solução em *Severed Dawn*: Evolução Dentro da Própria Run
A evolução dos inimigos ocorre de forma contínua e dinâmica ao longo dos biomas, atrelada ao **nível do jogador**, usando uma **escala assimétrica suave (3 para 1)**:
* Para cada +10% de poder que o jogador adquire, os inimigos ganham apenas +3% a +4% de vida/dano.
* A verdadeira transformação do inimigo **NÃO são números inflados**, mas sim o **desbloqueio orgânico de novos golpes e IA**.

---

## 3. Especificação dos 3 Tiers de Evolução

| Tier | Marco de Nível | Golpes Disponíveis | Comportamento Padrão | Multiplicador | Recursos Especiais |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Tier 1 (Recruta)** | Nível 1+ (Início) | ⚪ Ataque Branco (Normal) | `AGGRESSIVE_STALK` | 1.0x | Comportamento básico de aproximação |
| **Tier 2 (Veterano)** | Nível 4+ (Mid-Run) | ⚪ Branco + 🟡 Amarelo (Pesado) | `DEFENSIVE_RETREAT` / Stalk Veloz | 1.25x | Kiting tático, golpes com Hyper-Armor |
| **Tier 3 (Elite)** | Nível 8+ (Late-Run) | ⚪ Branco + 🟡 Amarelo + 🔴 Vermelho | `ADAPTIVE` (Evasivo pós-bloqueio) | 1.60x | Hyper-Armor ativada, chance de Spawn Elite |

### Regras de Herança em Cascata:
1. **Golpes são Cumulativos:** O Tier 2 herda os ataques do Tier 1 e soma os novos marcados; o Tier 3 reúne todo o repertório.
2. **Comportamento é Sobrescrito:** O maior tier ativo sempre comanda a atitude da IA no cooldown.
3. **Sem Duplicação de Cenas:** Cada monstro possui uma única cena `.tscn` com a Ficha de Tiers no Inspector.

### Dinâmica de Cooldown e Footsies (Espaçamento Inteligente):
Durante a janela de cooldown de ataque, o inimigo não fica congelado colado no jogador:
* **`STAND_GROUND`:** Posição firme/imóvel (sentinelas, torretas, partes de chefes).
* **`AGGRESSIVE_STALK` (Moderado):** No meio do cooldown, recua um passo para manter distância de guarda (~38-44px); nos últimos momentos do cooldown (restam <= 0.45s), avança de volta para a distância de corte (~22-24px) e ataca.
* **`DEFENSIVE_RETREAT` (Defensivo):** Recua consideravelmente (~65-80px) criando zona de segurança enquanto está vulnerável; só avança gradualmente quando o ataque é rearmado.
* **`ADAPTIVE` (Tático de Elite):** Footsies ágil de média distância (~52-70px) a alta velocidade (0.95x). Se o player bloquear ou der parry, realiza esquiva rápida para trás (1.3x). Nos momentos finais do cooldown, desfere um **bote em arrancada rápida (1.2x)** fechando o espaço instantaneamente para o próximo golpe surpresa.

---

## 4. Estrutura Padrão no Inspector do Godot

Todo inimigo deve exportar estes grupos organizados:

```gdscript
# 1. Base Stats
@export_group("Base Stats")
@export var is_elite: bool = false ## Se marcado true no mapa, sempre será Elite 100% garantido
@export var can_move: bool = true
@export var takes_knockback: bool = true
@export var max_health: float = 60.0
@export var patrol_speed: float = 40.0
@export var move_speed: float = 85.0
@export var friction: float = 800.0

# 2. Perception & Range
@export_group("Perception & Range")
@export var spot_range: float = 340.0
@export var back_awareness_range: float = 140.0
@export var attack_range: float = 30.0
@export var lose_target_range: float = 420.0

# 3. Attack Balancing
@export_group("Attack Balancing")
@export var normal_damage: float = 12.0
@export var heavy_damage: float = 20.0
@export var perilous_damage: float = 32.0
@export_range(0.1, 2.0, 0.05, "suffix:s") var telegraph_duration: float = 0.45
@export_range(0.0, 20.0, 0.05, "suffix:s") var attack_cooldown: float = 2.0
@export_range(0.1, 1.0, 0.05) var cooldown_speed_mult: float = 0.45

# 4. Tier 1 (Base / Nível 1+)
@export_group("Tier 1 (Base - Lv 1+)")
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_1_attacks: int = 1
@export var tier_1_behavior: CooldownBehavior = CooldownBehavior.AGGRESSIVE_STALK
@export var tier_1_damage_mult: float = 1.0
@export var tier_1_health_mult: float = 1.0

# 5. Tier 2 (Veterano / Nível 4+)
@export_group("Tier 2 (Veteran - Lv 4+)")
@export var tier_2_min_level: int = 4
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_2_attacks: int = 2
@export var tier_2_behavior: CooldownBehavior = CooldownBehavior.DEFENSIVE_RETREAT
@export var tier_2_damage_mult: float = 1.25
@export var tier_2_health_mult: float = 1.30

# 6. Tier 3 (Elite / Nível 8+)
@export_group("Tier 3 (Elite - Lv 8+)")
@export var tier_3_min_level: int = 8
@export_flags("White (Normal)", "Yellow (Heavy)", "Red (Perilous)") var tier_3_attacks: int = 4
@export var tier_3_behavior: CooldownBehavior = CooldownBehavior.ADAPTIVE
@export var tier_3_damage_mult: float = 1.60
@export var tier_3_health_mult: float = 1.75
@export var tier_3_has_hyper_armor: bool = true
@export var tier_3_can_be_elite: bool = true
@export_range(0.0, 1.0, 0.05) var tier_3_elite_chance: float = 0.25

# 7. Respawn & Debug
@export_group("Respawn (Test Mode)")
@export var respawn_enabled: bool = true
@export var respawn_delay: float = 4.0
```

---

## 5. Ferramenta de Teste Rápido In-Game

* **Atalho `T`:** Durante a execução do jogo na sala de teste, pressionar a tecla `T` alterna o nível do jogador e o Tier ativo dos inimigos:
  * `T` ➔ **Tier 2 (Veterano)** ➔ `T` ➔ **Tier 3 (Elite)** ➔ `T` ➔ **Tier 1 (Recruta)**.
* Ao acionar o atalho, um aviso visual é emitido no HUD e todos os inimigos da sala respawnam e se adaptam instantaneamente ao novo Tier sem necessidade de reiniciar a cena.
