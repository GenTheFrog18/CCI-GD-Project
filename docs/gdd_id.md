# Delvers of the Abyss — Dokumen Desain Game

> Status: sumber desain build game jam. Versi Inggris otoritatif. Keputusan naratif yang belum dijawab ditandai `TBD — perlu jawaban lead` dan dikumpulkan di `pertanyaan_lanjutan_gdd.md`.

## 1. Tujuan dan Konsep Utama

Dokumen ini menjelaskan desain yang dialami pemain kepada tim jam, supervisor, artist, programmer, audio, dan tester. Kepemilikan teknis berada di `fondasi_teknis_godot.md` dan `docs/implementation/`.

`PLAYER_NAME` adalah anak perempuan penuh rasa ingin tahu yang turun ke Abyss untuk mengungkap misterinya dan mencari orang tuanya. Ia bertahan melalui persiapan rute, mempelajari makhluk, dan menggabungkan relic secara kreatif, bukan mengandalkan combat langsung.

- Genre utama: eksplorasi 2D.
- Genre pendukung: extraction roguelite dan petualangan survival sistemik.
- Target run: sekitar 30 menit.
- Target pemain: pengunjung game jam dengan pengalaman platformer dasar.
- Inspirasi: Made in Abyss, Terraria, Noita, Rain World, dan Spelunky. Setting ini orisinal, bukan adaptasi langsung.

## 2. Pilar Desain

1. **Relic kreatif:** item menyelesaikan situasi, bukan hanya menjadi senjata.
2. **Interaksi dunia/makhluk:** sight, sound, force, status, terrain, dan makhluk lain lebih penting daripada adu damage.
3. **Eksperimen/knowledge:** relic yang belum dikenal mendorong eksperimen aman dan makin dipahami antar-run.
4. **Rencanakan kepulangan:** descent hanyalah setengah ekspedisi; ascent harus disiapkan menghadapi musuh dan Curse.

Game ini bukan platformer combat, Metroidvania, game grinding, terrain prosedural, atau game yang sengaja menghukum pemain.

## 3. Pengalaman yang Dituju

Persiapan/descent awal menimbulkan rasa ingin tahu; encounter menimbulkan kehati-hatian; penemuan interaksi menimbulkan kegembiraan. Keputusan inventory, rute, dan pulang harus terasa penuh pertimbangan, bukan membingungkan. Kesulitan berasal dari resource, rute, makhluk, dan risiko ascent; kegagalan harus dapat dipahami dan dicegah.

## 4. Gameplay Inti

Urutan biasa di Layer 1:

1. mengamati section buatan tangan dan makhluknya;
2. memilih anchor Rope aman dan menyiapkan jalan pulang;
3. turun, mengambil supply/relic, dan memilih barang yang layak dibawa;
4. menghindari, mengalihkan, memanipulasi, atau melawan dengan relic;
5. mengelola health, berat, status, dan supply;
6. naik hati-hati, beristirahat untuk me-reset Curse, lalu pulang atau lanjut turun.

Loop ekspedisi penuh, ritme pulang, fiksi kematian, replay, tutorial, dan rute presentasi masih `TBD — perlu jawaban lead`.

## 5. Run dan Progresi

- Seed memilih variasi section buatan tangan dan hasil placer deterministik; terrain tidak prosedural.
- Barat terbuka dan menekankan knockback/ancaman terbang. Timur rapat dan menekankan banyak ancaman kecil/hazard.
- Setiap slot dapat memiliki variasi traversal dan musuh dengan tingkat kesulitan sebanding.
- Gatekeeper/ancaman besar tetap; encounter biasa boleh dipilih placer.
- Semua rute wajib dapat selesai tanpa membunuh musuh biasa.
- Kematian mengakhiri living run. Knowledge bertahan; inventory, dunia, dan progres run di-reset.
- Build berakhir saat entrance Layer 3 diinteraksi. Layer 3 tidak playable.

Fiksi kematian, kemenangan, layanan surface, whistle, dan knowledge relic masih `TBD — perlu jawaban lead`.

## 6. Dunia

### Surface

Hub persiapan/pemulihan dengan toko, replacement, informasi, dan pintu kedua rute Layer 1. Detail karakter masih `TBD — perlu jawaban lead`.

### Layer 1

Tebing dan meadow hijau terang dengan gua redup. Barat terbuka; timur rapat. Layer ini mengajarkan Rope, manipulasi sound/sight, kombinasi makhluk, dan Curse pertama.

### Layer 2

Bagian atas inverted forest dengan kanopi terbalik. Bagian tengah outpost/toko dan hutan berbahaya. Bagian bawah gauntlet monster sebelum Layer 3.

Quest authority opsional meminta relic yang belum didesain dan memberi Moon Whistle serta powerful relic terpisah. Keduanya membantu tetapi bukan hard key. Identitasnya masih `TBD — perlu jawaban lead`.

## 7. Pemain

Protagonis adalah anak perempuan yang mencari misteri Abyss dan orang tuanya. Nama, umur, latihan, hubungan surface, dan gaya dialog masih `TBD — perlu jawaban lead`; `PLAYER_NAME` sengaja mudah diganti.

Kemampuan inti: movement, variable jump, item menuju cursor, interaksi, inventory, weighted throw, Rope placement, dan Rope climbing. Pemain rentan; persiapan dan item memberi kekuatan.

## 8. Inventory dan Item

- Lima backpack, dua hotbar, satu slot whistle fisik.
- Klik kiri memakai primary eksplisit; klik kanan secondary eksplisit.
- Lemparan aktif tidak memberi physical damage biasa; lemparan tidak aktif boleh memberi damage impact.
- Item nyata memakai `ThrownItem` persisten; serangan sementara memakai `Projectile`.
- Berat memengaruhi burden, movement setelah capacity, jatuh, kecepatan lempar, dan massa impact.
- Knowledge bertambah hanya dari signature use yang berhasil; Info Book membuka deskripsi tersisa.

Content Layer 1: Red/Blue Whistle, Multitool, Rope, Throwable Rock, Bandage, Info Book, Numbing Pill, Sun Sphere, Lantern Crystal, Rattlepod, Hushcap, Cling Resin, Driftseed, dan Silver Weight.

## 9. Makhluk Layer 1

- **Tongue Amphibian:** lemah sendiri; memilih item dunia lalu mencuri satu item pemain.
- **Knockback Bird:** menjaga sarang; dua hit flock dalam dua detik memberi damage.
- **Thorn Bloom:** hazard netral diam yang melepas jarum bleed.
- **Lantern Snail:** hazard bercahaya yang menjerit/dazzle; kematian menjatuhkan Lantern Crystal.
- **Cave Spider:** sensitif sound; projectile memberi slow, poison, dan tracking mark.
- **Large Flyer:** ancaman udara persisten dengan POI buatan level designer dan dive mematikan.
- **Senior Diver:** penjaga yang mengenali rank Blue dan dapat dialihkan, dilewati, atau dikalahkan.

Semua dapat dibunuh. Combat mahal dan opsional. Hazard netral bereaksi tetapi tidak mengejar.

## 10. Ascension Curse

- Melacak titik terdalam dan menerapkan paket pada setiap band ascent sepuluh meter baru.
- Sepuluh detik dengan gerakan vertikal di bawah satu meter me-reset referensi.
- Numbing Pill menghabiskan threshold dengan aman tetapi mengurangi durasi tambahan.
- Layer 1 memodifikasi movement, healing, throw range, dan warna.
- Layer 2 hanya memberi health-cap sementara, penalti lempar/warna, dan movement stop sesekali.
- Surface dan safe zone me-reset secara aman.

## 11. Effect dan Interaksi Sistemik

Damage, force, status, agitation, sight obstruction, sound, dan target override memakai contract bersama. Effect meliputi bleed, poison, spider slow, resin, incapacitation, mark, dazzle, healing, suppression, Driftseed, dan kedua Curse. Musuh terbang mengabaikan slow biasa; Driftseed adalah pengecualian.

## 12. UI dan Feedback

HUD utama: health, hotbar, whistle fisik, nama status, uang, berat, prompt, autosave, dan threat marker. Inventory terbuka sebagai buku animasi: lima slot backpack di halaman kiri, dua slot hotbar khusus dan whistle di halaman kanan, detail item terpilih, tautan submenu yang dapat dikonfigurasi di kanan bawah, dan dunia tetap terlihat gelap di belakangnya. Damage memakai flash merah/putih; status tampil di bawah health; overlay tidak menutup HUD; warning attack memakai `!` dan segitiga; F3 berada di kanan atas.

## 13. Art, Animasi, Audio, Aksesibilitas

- Viewport 640×360; sekitar 32 px/meter.
- Player 32×32; item boleh 16×16 dengan integer scale dan collision terpisah.
- Animasi enemy hanya `idle`, `move`, `attack`; state AI boleh memakai ulang.
- Pivot bottom-centre dan nearest filtering.
- Arah audio final belum dikunci. Cue gameplay harus menjelaskan serangan, whistle, movement, activation, dan distraction.
- Damage/knockback besar wajib memiliki warning. Overlay tidak menutup HUD. Reduced-effects di luar scope jam, sehingga default harus singkat dan jelas.

## 14. Batas dan Kriteria Sukses

Godot 4.7.1, keyboard/mouse, Linux-first, terrain buatan tangan, placement deterministik, placeholder, dan tuning berbasis data bersifat otoritatif. Art/audio/balance final, narasi lengkap, roster Layer 2, quest/reward relic, dan Layer 3 playable berada di luar paket.

Build berhasil jika pemain baru dapat bersiap, turun, menggabungkan relic, melewati dua encounter sistemik, mengalami/mengatasi Curse, pulang membawa nilai, melewati senior diver, mencapai Layer 2, dan memahami hasil keputusannya.
