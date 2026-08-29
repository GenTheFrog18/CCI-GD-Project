# Indeks dan Otoritas Dokumentasi

> **Status:** audit GDD, README, technical foundation, authoring guide, dan live implementation contract selesai 30 Agustus 2026.

## Urutan otoritas

Jika dokumen bertentangan:

1. [`gdd_en.md`](gdd_en.md) — approved player-facing intent dan arah desain.
2. [`fondasi_teknis_godot.md`](fondasi_teknis_godot.md) — current shared runtime architecture.
3. [`implementation/`](implementation/) — current implemented content behavior.
4. [`panduan_programming.md`](panduan_programming.md) dan [`panduan_world_generation.md`](panduan_world_generation.md) — workflow/authoring contract.
5. Answered questionnaire — decision history.
6. [`reference/`](reference/) — proposal/arsip; tidak authoritative.

`gdd_id.md` adalah counterpart bahasa Indonesia. English GDD tetap authoritative. Code yang tidak sengaja berbeda dari approved design adalah bug, bukan keputusan desain baru.

## Design

- [GDD editable — English](gdd_en.md)
- [GDD editable — Bahasa Indonesia](gdd_id.md)
- [GDD PDF — English](delvers_of_the_abyss_gdd_en.pdf)
- [GDD PDF — Bahasa Indonesia](delvers_of_the_abyss_gdd_id.pdf)
- [Post-jam GDD/README questionnaire](post_jam_gdd_readme_questionnaire.md)
- [Narrative master reference](narrative_master_reference.md)

## Technical foundation dan workflow

- [Fondasi teknis Godot](fondasi_teknis_godot.md)
- [Panduan programming](panduan_programming.md)
- [Panduan world generation](panduan_world_generation.md)
- [Enemy designer/programmer handoff](enemy_implementation_handoff.md)

## Authoring guides

- [Map placer reference](map_placer_authoring_reference.md)
- [Map section tutorial](map_section_authoring_tutorial.md)
- [Item GUI tutorial](tutorial_menambah_item_dengan_gui_godot.md)

## Live implementation contracts

- [Layer 1 items](implementation/layer_1_items.md)
- [Layer 1 enemies](implementation/layer_1_enemies.md)
- [Effects](implementation/effects.md)
- [Ascension Curse](implementation/ascension_curse.md)
- [Layer 2 relic foundation](implementation/layer_2_relics.md)
- [Layer 2 enemy foundation](implementation/layer_2_enemies.md)
- [Layer 2 world foundation](implementation/layer_2_world_integration.md)

Layer 2 implementation foundation is not the current normal playable scope. Current build ends at Layer 2 gate.

## Decision history

- [Answered GDD/content questionnaire](answered_pertanyaan_klarifikasi_gdd_enemy_item_curse_effects.md)
- [Layer 2 questionnaire](pertanyaan_klarifikasi_layer_2.md)
- [Player questionnaire](pertanyaan_klarifikasi_player.md)
- [Foundation questionnaire](pertanyaan_klarifikasi_fondasi.md)
- [Follow-up GDD questions](pertanyaan_lanjutan_gdd.md)

Questionnaires preserve why old decisions were made. They do not override later GDD/technical contracts.

## Archive

- [Reference archive policy](reference/README.md)
- [Technical/specification history](reference/technical_history/README.md)

Archived files preserve proposals and implementation history. Do not implement them directly. First move still-valid intent into GDD/live contract and receive project-owner approval.
