#!/usr/bin/env python3
"""Sincroniza os 28 spritesheets do Player (`player_*_sheet.png`) com os frames individuais (`individual/*.png`).

Uso:
    python src/tools/player_sheet_sync.py unpack          # Gera apenas os frames individuais faltantes
    python src/tools/player_sheet_sync.py unpack --force  # Re-fatia todos os 28 sheets para individual/
    python src/tools/player_sheet_sync.py pack            # Re-empacota individual/ -> player_*_sheet.png
"""

from __future__ import annotations

import argparse
import os
import sys
from PIL import Image

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ADVENTURER_DIR = os.path.join(ROOT_DIR, "assets", "player", "adventurer")

# (sheet_rel, cell_w, cell_h, cols, rows, [individual_rel em ordem linha-por-linha])
MANIFEST: list[tuple[str, int, int, int, int, list[str]]] = [
    ("idle/player_idle_sheet.png", 83, 62, 2, 2, [f"idle/individual/adventurer_idle_{i:02d}.png" for i in range(4)]),
    ("idle/player_idle_sheathe_sheet.png", 83, 62, 2, 2, [f"idle/individual/adventurer_idle_sheathe_{i:02d}.png" for i in range(4)]),
    ("idle/player_idle_sheathe_waist_sheet.png", 83, 62, 1, 3, [f"idle/individual/adventurer_idle_sheathe_waist_{i:02d}.png" for i in range(3)]),
    ("idle/player_idle_break_1_sheet.png", 83, 62, 1, 3, [f"idle/individual/adventurer_idle_break_1_{i:02d}.png" for i in range(3)]),
    ("run/player_run_sheet.png", 83, 62, 2, 3, [f"run/individual/adventurer_run_{i:02d}.png" for i in range(6)]),
    ("jump/player_jump_sheet.png", 83, 62, 2, 2, [f"jump/individual/adventurer_jump_{i:02d}.png" for i in range(4)]),
    ("crouch/player_crouch_sheet.png", 83, 62, 2, 2, [f"crouch/individual/adventurer_crouch_{i:02d}.png" for i in range(4)]),
    ("fall/player_fall_sheet.png", 83, 62, 1, 2, [f"fall/individual/adventurer_fall_{i:02d}.png" for i in range(2)]),
    ("slide/player_slide_sheet.png", 83, 62, 1, 2, [f"slide/individual/adventurer_slide_{i:02d}.png" for i in range(2)]),
    ("roll/player_roll_sheet.png", 83, 62, 2, 2, [f"roll/individual/roll_{i}.png" for i in range(4)]),
    ("wall_slide/player_wall_slide_sheet.png", 83, 62, 1, 3, [f"wall_slide/individual/adventurer_wall_slide_{i:02d}.png" for i in range(3)]),
    ("corner_climb/player_corner_climb_sheet.png", 83, 76, 2, 3, [f"corner_climb/individual/adventurer_corner_climb_{i:02d}.png" for i in range(5)]),
    ("attack/player_attack1_sheet.png", 83, 62, 2, 3, [f"attack/individual/adventurer_attack1_{i:02d}.png" for i in range(5)]),
    ("attack/player_attack2_sheet.png", 83, 62, 2, 3, [f"attack/individual/adventurer_attack2_{i:02d}.png" for i in range(6)]),
    ("attack/player_attack3_sheet.png", 83, 62, 2, 3, [f"attack/individual/adventurer_attack3_{i:02d}.png" for i in range(6)]),
    ("attack/player_air_attack1_sheet.png", 83, 62, 2, 2, [f"attack/individual/adventurer_air_attack1_{i:02d}.png" for i in range(4)]),
    ("attack/player_air_attack3_sheet.png", 83, 62, 2, 4, [f"attack/individual/adventurer_air_attack3_{i:02d}.png" for i in range(7)]),
    ("cast/player_cast_sheet.png", 83, 62, 2, 2, [f"cast/individual/adventurer_cast_{i:02d}.png" for i in range(4)]),
    ("channeling/player_channeling_sheet.png", 83, 62, 1, 2, [f"channeling/individual/adventurer_channeling_{i:02d}.png" for i in range(2)]),
    ("block/player_block_sheet.png", 83, 62, 1, 3, [f"block/individual/adventurer_block_{i:02d}.png" for i in range(3)]),
    ("block_loop/player_block_loop_sheet.png", 83, 62, 1, 2, [f"block_loop/individual/adventurer_block_loop_{i:02d}.png" for i in range(2)]),
    ("bow/player_bow_sheet.png", 83, 62, 2, 4, [f"bow/individual/adventurer_bow_{i:02d}.png" for i in range(7)]),
    ("bow/player_bow_air_sheet.png", 83, 62, 2, 3, [f"bow/individual/adventurer_bow_air_{i:02d}.png" for i in range(6)]),
    ("crossbow/player_crossbow_sheet.png", 83, 62, 1, 3, [f"crossbow/individual/adventurer_crossbow_{i:02d}.png" for i in range(3)]),
    ("crossbow/player_crossbow_air_sheet.png", 83, 62, 1, 3, [f"crossbow/individual/adventurer_crossbow_air_{i:02d}.png" for i in range(3)]),
    ("pickup/player_pickup_sheet.png", 83, 62, 2, 2, [f"pickup/individual/adventurer_pickup_{i:02d}.png" for i in range(4)]),
    ("hurt/player_hurt_sheet.png", 83, 62, 1, 3, [f"hurt/individual/adventurer_hurt_{i:02d}.png" for i in range(3)]),
    ("death/player_death_sheet.png", 83, 62, 2, 1, [f"death/individual/adventurer_death_{i:02d}.png" for i in range(2)]),
]


def unpack(force: bool = False) -> int:
    created = 0
    for sheet_rel, cw, ch, cols, rows, indivs in MANIFEST:
        sheet_path = os.path.join(ADVENTURER_DIR, sheet_rel)
        sheet_im = Image.open(sheet_path).convert("RGBA")
        if sheet_im.size != (cw * cols, ch * rows):
            print(f"ERRO: {sheet_rel} tem tamanho {sheet_im.size}, esperado {(cw * cols, ch * rows)}", file=sys.stderr)
            return 1
        for idx, indiv_rel in enumerate(indivs):
            indiv_path = os.path.join(ADVENTURER_DIR, indiv_rel)
            if not force and os.path.exists(indiv_path):
                continue
            os.makedirs(os.path.dirname(indiv_path), exist_ok=True)
            gx, gy = idx % cols, idx // cols
            crop = sheet_im.crop((gx * cw, gy * ch, (gx + 1) * cw, (gy + 1) * ch))
            crop.save(indiv_path)
            created += 1
            print(f"Fatiado: {indiv_rel}")
    print(f"Unpack concluído ({created} arquivos gerados).")
    return 0


def pack() -> int:
    updated = 0
    for sheet_rel, cw, ch, cols, rows, indivs in MANIFEST:
        sheet_path = os.path.join(ADVENTURER_DIR, sheet_rel)
        new_sheet = Image.new("RGBA", (cw * cols, ch * rows), (0, 0, 0, 0))
        for idx, indiv_rel in enumerate(indivs):
            indiv_path = os.path.join(ADVENTURER_DIR, indiv_rel)
            if not os.path.exists(indiv_path):
                print(f"ERRO: Frame faltando: {indiv_rel}", file=sys.stderr)
                return 1
            frame_im = Image.open(indiv_path).convert("RGBA")
            if frame_im.size != (cw, ch):
                print(f"ERRO: {indiv_rel} tem tamanho {frame_im.size}, esperado {(cw, ch)}", file=sys.stderr)
                return 1
            gx, gy = idx % cols, idx // cols
            new_sheet.paste(frame_im, (gx * cw, gy * ch))

        changed = True
        if os.path.exists(sheet_path):
            old_sheet = Image.open(sheet_path).convert("RGBA")
            if old_sheet.size == new_sheet.size and old_sheet.tobytes() == new_sheet.tobytes():
                changed = False
        if changed:
            new_sheet.save(sheet_path)
            updated += 1
            print(f"Empacotado: {sheet_rel}")
    print(f"Pack concluído ({updated} spritesheets atualizados).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Sincroniza frames individuais e spritesheets do Player.")
    parser.add_argument("action", choices=["unpack", "pack"], help="'unpack' fatia para individual/; 'pack' re-empacota para *_sheet.png")
    parser.add_argument("--force", action="store_true", help="No modo unpack, sobrescreve frames existentes.")
    args = parser.parse_args()
    if args.action == "unpack":
        return unpack(force=args.force)
    return pack()


if __name__ == "__main__":
    raise SystemExit(main())
