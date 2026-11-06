# 🌐 Referência do Sistema de Linguagem e Localização (i18n)

> [!IMPORTANT]
> **Documento Oficial de Arquitetura de Textos, Barks e Tradução — Severed Dawn**
> Todo texto exibido em tela (menus, HUD, barks do protagonista, diálogos com a família, descrições de armas e alertas do sistema) deve seguir rigorosamente as diretrizes deste documento.
> **Regra de Ouro:** NUNCA utilize strings literais (*hardcoded strings*) diretamente em nós, labels ou scripts GDScript.

---

## 1. Visão Geral & Filosofia Arquitetural

No ecossistema da **Godot 4**, a base de dados de localização não necessita de motores pesados de banco de dados relacional (como SQLite ou MySQL). A engine fornece uma infraestrutura nativa compilada, de altíssima performance e sem alocação dinâmica desnecessária, baseada no **`TranslationServer`** alimentado por tabelas **CSV** estruturadas.

* **O CSV como "Database" de Textos:** O arquivo `translations.csv` opera como a tabela relacional centralizada de todo o vocabulário do jogo.
* **Compilação Binária Automática:** Ao importar o arquivo `.csv`, a Godot 4 compila automaticamente cada coluna de idioma em arquivos binários otimizados de hash map (`.translation`).
* **Resolução O(1):** A busca por qualquer chave de texto através da função nativa `tr("CHAVE")` é executada em tempo constante O(1), sem impacto no framerate da física ou combate.
* **Idioma Base Inicial:** Todo o projeto é desenvolvido prioritariamente em Português Brasileiro (`pt_BR`), com colunas preparadas para Inglês (`en_US`) e futuras expansões globais.

---

## 2. Estrutura de Arquivos e Diretórios

A infraestrutura de localização fica centralizada dentro do núcleo do projeto (`src/core/`):

```text
src/
└── core/
    └── localization/
        ├── translations.csv       # Tabela mestre (o "Database" de textos)
        └── localization_service.gd # Singleton/Helper para barks aleatórios e utilitários
```

### Configuração no `project.godot`:
A tabela compilada é registrada na seção nativa de internacionalização da Godot:

```ini
[internationalization]

locale/translations=PackedStringArray("res://src/core/localization/translations.pt_BR.translation", "res://src/core/localization/translations.en_US.translation")
locale/fallback="pt_BR"
locale/test="pt_BR"
```

---

## 3. Padrão da Tabela de Tradução (CSV / DB de Strings)

O arquivo `translations.csv` utiliza cabeçalhos ISO de idioma e aspas duplas como delimitadores seguros contra quebras de linha e vírgulas:

```csv
keys,pt_BR,en_US
UI_HEALTH,Vida,Health
UI_FLASK_CHARGES,Chá,Tea
BARK_TEA_EMPTY_1,"Putz, acabou o chá!","Damn, out of tea!"
BARK_TEA_EMPTY_2,"Acabou o chá...","Out of tea..."
BARK_TEA_EMPTY_3,"Devia ter trazido mais chá.","Should've brought more tea."
BARK_TEA_EMPTY_4,"Já acabou o chá?...","Already out of tea?..."
ITEM_SWORD_BASE_NAME,"Espada do Viajante","Traveler's Sword"
ITEM_SWORD_BASE_DESC,"Lâmina rústica forjada pelo irmão antes da invasão.","Rustic blade forged by the brother before the invasion."
```

### Convenção Oficial de Prefixos das Chaves:

| Prefixo | Finalidade / Contexto | Exemplo |
| :--- | :--- | :--- |
| `UI_*` | Elementos de interface, barras, botões e labels | `UI_PAUSE_MENU`, `UI_PLAY_AGAIN` |
| `BARK_*` | Falas e pensamentos curtos e diegéticos no topo de personagens | `BARK_TEA_EMPTY_1`, `BARK_HURT_FALL` |
| `ITEM_*` | Nomes, subtítulos e descrições de armas, frascos e armaduras | `ITEM_TEA_FLASK_NAME`, `ITEM_BOW_DESC` |
| `LORE_*` | Falas e diálogos narrativos da Mãe, Irmão, Morte e NPCs | `LORE_MOTHER_GREETING`, `LORE_DEATH_PACT` |
| `MSG_*` | Alertas rápidos do sistema ou notificações de combate | `MSG_PARRY_COUNTER`, `MSG_TIER_UP` |

---

## 4. O Sistema de Barks e Variações Aleatórias

Muitas interações diegéticas (como tentar beber o chá da mãe com 0 cargas) exigem variação contextual para evitar repetição mecânica.

### 1. Padrão de Nomenclatura Indexada:
Para qualquer mensagem com múltiplas variantes aleatórias, as chaves no CSV utilizam o sufixo numérico contínuo iniciado em `_1`:
* `BARK_TEA_EMPTY_1`
* `BARK_TEA_EMPTY_2`
* `BARK_TEA_EMPTY_3`
* `BARK_TEA_EMPTY_4`

### 2. O Helper de Barks (`LocalizationService`):
O helper gerencia a seleção aleatória e implementa **memória anti-repetição imediata** (evitando que o herói diga exatamente a mesma frase duas vezes em seguida):

```gdscript
class_name LocalizationService
extends RefCounted

static var _last_picked: Dictionary = {}

## Retorna uma variante aleatória traduzida de uma chave base (ex: base="BARK_TEA_EMPTY", count=4)
static func get_random_variant(base_key: String, count: int) -> String:
	if count <= 1:
		return tr(base_key + "_1")
	
	var last_idx: int = _last_picked.get(base_key, -1)
	var available: Array[int] = []
	
	for i in range(1, count + 1):
		if i != last_idx:
			available.append(i)
	
	var chosen_idx: int = available.pick_random()
	_last_picked[base_key] = chosen_idx
	
	var final_key: String = "%s_%d" % [base_key, chosen_idx]
	return tr(final_key)
```

---

## 5. Como Aplicar em Novos Sistemas (Passo a Passo)

Ao implementar qualquer funcionalidade que envolva texto:

1. **Passo 1 (Adicionar ao CSV):**
   * Abra `src/core/localization/translations.csv` e adicione a nova linha com a chave e as traduções (`pt_BR` e `en_US`).
2. **Passo 2 (Chamar no GDScript ou Nó):**
   * **Texto Estático (UI / Labels):** Se você definir a propriedade `text` de um `Label` ou `Button` com o nome exato da chave (ex: `UI_HEALTH`), a Godot traduz automaticamente em tempo de execução sem precisar de código!
   * **Texto Dinâmico / Código:** Use a função global `tr("SUA_CHAVE")`.
     ```gdscript
     print(tr("MSG_TIER_UP"))
     ```
   * **Barks Aleatórios (Ex: Garrafa de Chá Vazia):**
     ```gdscript
     var bark_text: String = LocalizationService.get_random_variant("BARK_TEA_EMPTY", 4)
     floating_bark_label.display(bark_text)
     ```
3. **Passo 3 (Validação Headless):**
   * Rode sempre o validador para garantir que a Godot compila a tabela sem erros:
     ```powershell
     godot --headless --check-only --path .
     ```

---

## 6. Benefícios Práticos para o Projeto

* **Zero Dívida Técnica:** Nenhum texto precisará ser "reescrito" ou caçado no código no futuro.
* **Pronto para Lançamento Global:** A qualquer momento, basta exportar o CSV para tradutores adicionarem novas colunas (`es_ES`, `ja_JP`, `fr_FR`) sem tocar em uma única linha de GDScript.
* **Consistência de Tom e Lore:** A equipe e a IA mantêm toda a identidade de escrita da família, da Morte e do protagonista centralizada em um único arquivo consultável.

---

## 7. Diretriz de Tradução Humanlike & Contextualização (Anti-Google Translate)

> [!CAUTION]
> **Proibição Absoluta de Tradução Literal / Tradutor Automático:**
> O jogo rejeita traduções automáticas frias, secas ou literais que apenas substituem palavras de um dicionário. A IA deve atuar como uma **localizadora humana e roteirista de jogos**, adaptando expressões idiomáticas, gírias e o peso emocional de cada momento.

### 1. Pilares da Tradução Humanlike:
1. **Sensibilidade de Tom (Dark Fantasy Rústico):** O vocabulário deve soar condizente com um mundo devastado pela tirania e pelo massacre, mantendo a autenticidade de pessoas comuns em uma família simples do campo.
2. **Transcriação de Barks e Gírias:** Expressões coloquiais como *"Putz, acabou o chá!"* não podem ser vertidas como *"Put, finished the tea"*, mas sim transcriadas para equivalentes naturais em inglês (ex: *"Damn it, out of tea!"* ou *"Well, that's the last drop..."*).
3. **Contexto de Cena Sempre Ativo:** A IA deve avaliar quem está falando, para quem está falando e o estado físico da personagem (ofegante, frustrado, descansando, assustado) antes de definir a versão em outro idioma.

### 2. Comparativo de Qualidade Obrigatório:

| Chave | Texto Original (`pt_BR`) | ❌ Tradução Robótica (PROIBIDA) | ✅ Tradução Humanlike Oficial (`en_US`) |
| :--- | :--- | :--- | :--- |
| `BARK_TEA_EMPTY_1` | "Putz, acabou o chá!" | "Put, the tea is finished!" | "Damn it, out of tea!" |
| `BARK_TEA_EMPTY_2` | "Acabou o chá..." | "Finished the tea..." | "Not a single drop left..." |
| `BARK_TEA_EMPTY_3` | "Devia ter trazido mais chá." | "Should have brought more tea." | "I really should've packed more tea." |
| `BARK_TEA_EMPTY_4` | "Já acabou o chá?..." | "Already ended the tea?..." | "Out of tea already?..." |
| `ITEM_SWORD_BASE_NAME`| "Espada do Viajante" | "Sword of the Traveler" | "Traveler's Blade" |
| `LORE_MOTHER_TEA_OFFER`| "Tome com calma, meu filho. O mundo lá fora não tem pressa de te ver morrer." | "Drink with calm, my son. The outside world is not in a hurry to see you die." | "Drink it slowly, love. The horrors out there won't mind waiting for your blood." |
