# Indeks dan Otoritas Dokumentasi

> **Status:** Indeks pasca-game-jam, 30 Agustus 2026. Audit penuh kesesuaian code dan dokumentasi teknis dijadwalkan sebagai pekerjaan berikutnya.

## Urutan otoritas

Gunakan urutan berikut ketika dokumen bertentangan:

1. [`gdd_en.md`](gdd_en.md) — intent player-facing dan arah desain yang sudah disetujui.
2. [`fondasi_teknis_godot.md`](fondasi_teknis_godot.md) — arsitektur teknis bersama.
3. [`panduan_programming.md`](panduan_programming.md) — workflow implementation, style, dan review code.
4. [`panduan_world_generation.md`](panduan_world_generation.md) — kontrak authoring section, placer, generation, debug, dan acceptance.
5. [`implementation/`](implementation/) — kontrak behavior yang sudah diimplementasikan untuk enemy, item, effect, Curse, dan Layer 2.
6. Questionnaire yang sudah dijawab — riwayat keputusan, bukan kontrak runtime langsung.
7. [`reference/`](reference/) — arsip ide/spec lama; tidak dapat mengalahkan keputusan terbaru.

`gdd_id.md` adalah padanan bahasa Indonesia dari GDD English. Jika terjemahan berbeda, perbaiki versi Indonesia agar mengikuti versi English.

Perbedaan tidak sengaja antara code dan GDD adalah bug, bukan perubahan desain otomatis. Perubahan yang disengaja harus memperbarui GDD dan dokumen implementation terkait setelah disetujui pemilik project.

## Game Design Document

- [GDD editable — English](gdd_en.md)
- [GDD editable — Bahasa Indonesia](gdd_id.md)
- [GDD PDF — English](delvers_of_the_abyss_gdd_en.pdf)
- [GDD PDF — Bahasa Indonesia](delvers_of_the_abyss_gdd_id.pdf)
- [Questionnaire GDD/README pasca-game-jam](post_jam_gdd_readme_questionnaire.md)

## Fondasi dan workflow

- [Fondasi teknis Godot](fondasi_teknis_godot.md)
- [Panduan programming](panduan_programming.md)
- [Panduan world generation](panduan_world_generation.md)
- [Keputusan world generation](keputusan_world_generation.md)
- [Referensi authoring placer](map_placer_authoring_reference.md)
- [Tutorial authoring section map](map_section_authoring_tutorial.md)
- [Tutorial menambah item melalui GUI](tutorial_menambah_item_dengan_gui_godot.md)

## Kontrak implementation utama

- [Layer 1 items](implementation/layer_1_items.md)
- [Layer 1 enemies](implementation/layer_1_enemies.md)
- [Effects](implementation/effects.md)
- [Ascension Curse](implementation/ascension_curse.md)
- [Layer 2 relics](implementation/layer_2_relics.md)
- [Layer 2 enemies](implementation/layer_2_enemies.md)
- [Layer 2 world integration](implementation/layer_2_world_integration.md)
- [Enemy implementation handoff](enemy_implementation_handoff.md)
- [Dialogue system expansion](dialogue_system_expansion_spec.md)
- [Ground traversal pathfinding](ground_traversal_pathfinding_programmer_handoff.md)
- [World darkness and lighting](world_darkness_and_lighting_programmer_handoff.md)

Enemy-specific programmer specifications remain useful for design history and specialized behavior. When they conflict with `implementation/`, verify current code and report the conflict before editing.

## Narrative dan decision history

- [Narrative master reference](narrative_master_reference.md)
- [Answered GDD/content questionnaire](answered_pertanyaan_klarifikasi_gdd_enemy_item_curse_effects.md)
- [Layer 2 questionnaire](pertanyaan_klarifikasi_layer_2.md)
- [Player questionnaire](pertanyaan_klarifikasi_player.md)
- [Foundation questionnaire](pertanyaan_klarifikasi_fondasi.md)

File di `reference/` dipertahankan untuk sejarah project. Jangan mengimplementasikan isi arsip tanpa keputusan baru di GDD atau dokumen implementation yang aktif.
