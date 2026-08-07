# Pertanyaan Klarifikasi World & Map Generation

**Status:** menunggu jawaban lead designer sebelum kontrak world generation dan graybox map diimplementasikan.

Dokumen ini merangkum hal yang belum dikunci setelah membaca ulang:

- `fondasi_teknis_godot.md`
- `panduan_programming.md`
- jawaban pada `pertanyaan_klarifikasi_fondasi.md`
- kedua roadmap lama dalam `reference/`
- spesifikasi item yang memengaruhi terrain, source, rope, dan placer
- prototype `WorldSection`, `DeterministicPlacer`, save, dan smoke test saat ini

Jawab langsung setelah `**Jawaban:**`. Jawaban singkat seperti “sesuai saran” diperbolehkan. Jika keputusan belum dapat dibuat, tulis `TBD` dan jelaskan batas aman yang boleh dipakai programmer sementara.

Label prioritas:

- **BLOCKER** — harus dijawab sebelum kontrak generator dibuat.
- **SEBELUM GRAYBOX** — harus dijawab sebelum tim membuat section yang akan dipakai.
- **SEBELUM CONTENT** — sistem dasar dapat dibuat, tetapi penempatan final menunggu jawaban.
- **NANTI** — aman ditunda tanpa merusak fondasi.

---

# Keputusan yang sudah dipahami dan tidak perlu dijawab ulang

1. Dunia menggunakan section buatan tangan; generator tidak membuat geometry atau terrain prosedural.
2. Generator memilih variasi section dan hasil placer secara deterministik dari seed run dan ID stabil.
3. Kontrak sementara saat ini adalah viewport 640×360, skala 32 px/m, section 640×1600 px, dan tiga section vertikal per sisi per layer.
4. Ada dua layer playable. Layer 3 tidak playable; build berakhir di entrance Layer 3.
5. Setiap layer mempunyai rute east dan west. Keduanya diakses dari gate di Layer 0 dan tidak boleh dianggap terhubung pada setiap kedalaman.
6. Target penuh lama adalah 12 slot terpilih: tiga slot × dua sisi × dua layer. Dua variasi per slot berarti target penuh 24 scene section.
7. Satu variasi graybox valid untuk setiap slot dibuat sebelum variasi kedua.
8. Semua section wajib mempunyai jalur turun dan naik; random loot tidak boleh menjadi syarat satu-satunya untuk menyelesaikan rute.
9. Enemy mati dan source yang dipanen tidak respawn selama living run.
10. Pilihan section, hasil placer, object yang dihancurkan/diambil, rope, dan item yang berasal dari player harus bertahan setelah Continue.
11. Surface hub, Layer 1 gate, Layer 2 shop, gauntlet menuju Layer 3, dan entrance Layer 3 adalah lokasi authored khusus.
12. Stable ID tidak boleh berasal dari nama node atau `NodePath` runtime.

Jika salah satu poin di atas ternyata tidak benar, koreksi terlebih dahulu sebelum menjawab bagian lain.

---

# A. Bentuk dunia dan koneksi rute

## A1 — Diagram macro world — BLOCKER

Bagaimana urutan node dunia dari surface sampai ending, termasuk titik split dan titik bertemunya east/west?

Dokumentasi menyebut dua rute terpisah, tetapi belum menjelaskan apakah keduanya bertemu di gate Layer 1, Layer 2 shop, dan gate Layer 3.

**Saran:** gunakan graph sementara berikut: `Surface → pilih East/West → 3 section Layer 1 → ruang gate bersama → pilih East/West → section atas Layer 2 → shop bersama → section bawah Layer 2 → gauntlet bersama → entrance Layer 3`.

**Jawaban:**

## A2 — Apakah pilihan east/west mengunci rute? — BLOCKER

Setelah memilih east atau west, apakah player boleh kembali ke surface lalu memilih sisi lain dalam run yang sama?

Ini menentukan apakah pilihan rute adalah komitmen, shortcut, atau sekadar pintu masuk.

**Saran:** jangan mengunci pilihan. Player boleh kembali dan mencoba sisi lain selama run hidup.

**Jawaban:**

## A3 — Tempat east/west dapat saling berpindah — BLOCKER

Di titik mana player boleh berpindah dari east ke west: hanya surface, setiap gate/shop bersama, connector tertentu, atau tidak pernah di bawah surface?

**Saran:** izinkan perpindahan hanya di ruang bersama yang authored: surface, gate Layer 1, dan shop Layer 2. Section biasa tidak mempunyai connector horizontal antar-rute.

**Jawaban:**

## A4 — Satu world fisik atau branch scene terpisah — BLOCKER

Apakah east dan west berada berdampingan dalam satu koordinat dunia besar, atau masing-masing merupakan branch scene yang dimuat dari hub?

Satu world besar lebih mudah terasa seamless, tetapi branch scene terpisah lebih ringan dan tidak memerlukan jarak horizontal kosong di antara rute.

**Saran:** gunakan satu world assembly per layer dengan dua kolom fixed slot dan ruang junction authored. Jangan memakai teleport antar-section biasa.

**Jawaban:**

## A5 — Transisi antar-layer — BLOCKER

Apakah melewati gate Layer 1 menuju Layer 2 terjadi tanpa loading/fade dalam world yang sama, atau melalui pergantian scene singkat?

“Seamless” pada dokumen lama jelas berlaku antar-section, tetapi belum pasti berlaku antar-layer.

**Saran:** section dalam satu layer seamless; gate antar-layer boleh memakai fade singkat dan scene transition agar save, camera, dan content activation lebih aman.

**Jawaban:**

## A6 — Bentuk Layer 2 di sekitar shop — BLOCKER

Apakah shop Layer 2 benar-benar berada di midpoint vertikal dan menjadi junction yang harus dilalui kedua rute, atau merupakan ruang samping opsional?

**Saran:** jadikan shop ruang aman bersama yang wajib dilewati, tetapi transaksi tetap opsional. Rute east/west bertemu di shop lalu dapat bercabang lagi.

**Jawaban:**

## A7 — Posisi quest gatekeeper, reward, dan gauntlet — BLOCKER

Konfirmasi urutan fisik: gatekeeper berada di shop Layer 2, memberikan Moon Whistle dan powerful relic, lalu player menempuh section/ruang gauntlet sebelum entrance Layer 3.

Berapa banyak ruang atau section di antara shop dan ending, dan apakah ruang tersebut termasuk enam slot Layer 2 atau scene khusus tambahan?

**Saran:** gatekeeper berada di shop; satu slot terbawah per sisi mengarah ke satu scene gauntlet bersama; entrance Layer 3 adalah ujung scene khusus tersebut.

**Jawaban:**

## A8 — Arah perjalanan dan gate satu arah — BLOCKER

Apakah semua gate dan ruang khusus dapat dilalui kembali ke arah atas setelah dibuka? Apakah ada drop satu arah yang disengaja?

**Saran:** semua progression gate yang sudah dibuka dapat dilalui dua arah. Drop satu arah hanya boleh menjadi jalur opsional jika tersedia rute kembali yang jelas.

**Jawaban:**

## A9 — Trigger ending — SEBELUM GRAYBOX

Apa yang tepatnya memicu ending: menyentuh area entrance, berinteraksi dengan gate, melewati garis tertentu, atau menyelesaikan dialogue?

**Saran:** gunakan `Area2D` authored di entrance Layer 3 yang hanya aktif setelah reward gatekeeper diperoleh; masuk area memicu ending sekali.

**Jawaban:**

---

# B. Kontrak section, seam, dan traversal

## B1 — Konfirmasi ukuran section — BLOCKER

Apakah kontrak 640×1600 px tetap digunakan untuk seluruh section east/west pada prototype world generation pertama?

Asset item 16×16 tidak menentukan ukuran map. Mengubah ukuran setelah graybox dimulai akan memaksa revisi collision, camera, dan art.

**Saran:** kunci 640×1600 untuk prototype pertama; evaluasi hanya setelah dua section tersambung dapat dimainkan.

**Jawaban:**

## B2 — Ukuran ruang khusus — SEBELUM GRAYBOX

Apakah surface, gate, shop, dan gauntlet juga harus 640×1600, atau boleh mempunyai ukuran sendiri?

**Saran:** section route memakai ukuran tetap; ruang khusus boleh berbeda tetapi wajib menyediakan anchor masuk/keluar dan camera bounds yang sama jelasnya.

**Jawaban:**

## B3 — Origin dan arah koordinat — BLOCKER

Di mana origin setiap section: kiri atas `(0,0)`, tengah atas, atau posisi entrance? Apakah exit selalu berada di bawah pada `y = 1600`?

**Saran:** root section di kiri atas `(0,0)`, Y positif ke bawah, entry seam di sisi atas, exit seam di sisi bawah. Transform global hanya ditentukan world assembler.

**Jawaban:**

## B4 — Bentuk seam, bukan hanya titik anchor — BLOCKER

Berapa lebar bukaan seam dan ruang bebas minimum di sekitarnya? Marker satu titik belum cukup menjamin collision benar-benar tersambung.

**Saran:** setiap seam memiliki marker tengah, lebar bukaan tetap, dan rectangle clearance. Validator memeriksa posisi marker serta tidak adanya collision di clearance.

**Jawaban:**

## B5 — Jumlah entry/exit per section — BLOCKER

Apakah setiap section hanya mempunyai satu entry atas dan satu exit bawah, atau boleh memiliki beberapa jalur masuk/keluar?

**Saran:** fondasi pertama memakai tepat satu seam utama atas dan bawah. Cabang lokal boleh ada di dalam section tetapi kembali ke jalur utama.

**Jawaban:**

## B6 — Universal seam atau beberapa profile — BLOCKER

Apakah semua variasi menggunakan posisi seam yang identik, atau generator perlu mencocokkan tipe seam seperti `left`, `centre`, dan `right`?

**Saran:** gunakan satu universal seam profile per slot pada jam build. Variasi boleh berbeda di dalam, tetapi entry/exit slot yang sama harus identik.

**Jawaban:**

## B7 — Batas horizontal section — SEBELUM GRAYBOX

Apakah sisi kiri/kanan selalu terrain tertutup, dapat berisi jurang keluar bounds, atau dapat mempunyai connector ke ruang samping?

**Saran:** sisi luar route tertutup collision. Connector samping harus berupa anchor eksplisit dan hanya digunakan pada junction atau optional room yang direncanakan.

**Jawaban:**

## B8 — Terrain destructible — BLOCKER

Apakah terrain utama selalu tidak dapat dihancurkan, dengan breakable relic rock sebagai object terpisah saja?

Ini menentukan apakah section dapat memakai collision statis sederhana atau memerlukan sistem terrain mutable.

**Saran:** terrain utama tidak destructible. Semua breakable adalah scene object authored/placer, bukan bagian dari terrain collision utama.

**Jawaban:**

## B9 — Metrik traversal player — SEBELUM GRAYBOX

Berapa batas desain untuk tinggi lompatan, jarak horizontal, tinggi jatuh aman, lebar platform minimum, dan ruang kepala player?

Programmer dapat mengukur nilai dari controller saat ini, tetapi desainer perlu menetapkan margin aman agar art team tidak membuat lompatan pixel-perfect.

**Saran:** buat satu `movement_metrics` graybox test dan gunakan 80% kemampuan maksimum player sebagai batas jalur wajib.

**Jawaban:**

## B10 — Peran Rope dalam rute wajib — BLOCKER

Apakah Rope hanya membuat shortcut/rute pulang lebih aman, atau ada bagian yang benar-benar memerlukannya?

Dokumen lama mengatakan selalu harus ada rute alami yang lebih berbahaya dan random loot tidak boleh memblokir completion.

**Saran:** main route selalu dapat diselesaikan tanpa Rope. Rope memperpendek, mengamankan, atau membuka optional loot.

**Jawaban:**

## B11 — Anchor Rope — SEBELUM GRAYBOX

Apakah Rope dapat ditempatkan pada semua ceiling/ledge valid berdasarkan physics, atau hanya pada marker anchor authored?

**Saran:** gunakan marker `RopeAnchor` authored. Ini lebih mudah divalidasi, disimpan, dan diseimbangkan daripada menempel di semua terrain.

**Jawaban:**

## B12 — Arti inverted canopy Layer 2 — BLOCKER

Apakah Layer 2 hanya memiliki visual/geometry kanopi terbalik, atau gravitasi dan arah traversal player juga berubah?

Ini mengubah section template, camera, movement, rope, enemy placement, dan seam.

**Saran:** gravitasi player tetap normal. “Inverted canopy” adalah bentuk terrain dan art; Driftseed memberi variasi gravity sementara.

**Jawaban:**

## B13 — Camera bounds dan perpindahannya — SEBELUM GRAYBOX

Apakah camera dibatasi per section, per layer, atau mengikuti player tanpa bounds? Bagaimana bounds berpindah saat player melewati seam?

**Saran:** setiap section mengekspor rectangle camera bounds. World controller memilih bounds section aktif dan melakukan blend singkat tanpa menghentikan gameplay.

**Jawaban:**

## B14 — Safe zone pada seam — SEBELUM GRAYBOX

Berapa area di sekitar entry/exit yang harus bebas dari enemy, hazard, dan placer agar load/Continue tidak langsung membunuh player?

**Saran:** sediakan satu viewport-height atau minimal beberapa detik traversal aman pada setiap seam penting; validator melarang enemy placer di area tersebut.

**Jawaban:**

## B15 — Out-of-bounds section — BLOCKER

Apa yang terjadi jika player keluar sisi atau jatuh melewati section tanpa seam valid: kembali ke last-safe position dengan 1 HP, mati, atau pindah section?

**Saran:** hanya crossing melalui seam volume yang memindahkan section. Keluar bounds lain menggunakan fallback yang sudah ada: last-safe position dan tepat 1 HP.

**Jawaban:**

---

# C. Pemilihan section dan seed

## C1 — Kapan dunia di-assemble — BLOCKER

Apakah semua 12 section dibuat saat New Game/load, satu layer pada satu waktu, atau hanya section di sekitar player?

**Saran:** untuk jam build, pilih layout seluruh run saat New Game tetapi instantiate satu layer aktif beserta ruang junction-nya. Hindari streaming per-section sebelum profiling membuktikan perlu.

**Jawaban:**

## C2 — Randomness per slot — BLOCKER

Apakah pilihan variasi setiap slot harus berasal dari `seed + slot_id`, sehingga menambah slot baru tidak mengubah pilihan slot lama?

**Saran:** ya. Jangan memakai satu RNG sequential global untuk seluruh layout.

**Jawaban:**

## C3 — Bobot variasi — SEBELUM CONTENT

Apakah variasi A/B selalu 50:50, atau setiap variasi mempunyai weight?

**Saran:** dukung weight data sederhana sejak awal; gunakan bobot sama sampai playtest memberi alasan lain.

**Jawaban:**

## C4 — Aturan kombinasi antar-section — BLOCKER

Selain seam, apakah ada kombinasi variasi yang dilarang karena difficulty, item requirement, tema, atau pengulangan?

**Saran:** jangan menambah solver constraint untuk prototype. Semua variasi sebuah slot wajib kompatibel dengan semua variasi tetangga.

**Jawaban:**

## C5 — Reuse scene antar-slot — SEBELUM CONTENT

Apakah satu scene section boleh digunakan pada beberapa slot sebagai fallback, atau setiap slot wajib mempunyai scene khusus?

**Saran:** izinkan reuse/redress sebagai fallback deadline, tetapi variation ID dan slot compatibility tetap eksplisit.

**Jawaban:**

## C6 — Pilihan layout disimpan atau dihitung ulang — BLOCKER

Saat Continue, apakah layout dibaca dari daftar variation ID tersimpan atau dihitung ulang hanya dari seed?

Menyimpan hasil melindungi run lama jika weight/pool berubah selama development.

**Saran:** simpan variation ID terpilih. Seed tetap disimpan untuk reproduksi dan placer.

**Jawaban:**

## C7 — Seed untuk player/debug — SEBELUM DEMO

Apakah seed perlu ditampilkan, dapat diketik saat New Game, atau hanya terlihat di debug UI/log?

**Saran:** random pada New Game; tampilkan dan izinkan copy/input hanya melalui debug panel selama jam.

**Jawaban:**

## C8 — Kegagalan validasi section — BLOCKER

Jika pool slot kosong, scene hilang, ID duplikat, atau seam invalid, apakah game memakai fallback atau menolak memulai run?

**Saran:** development build menghentikan generation dengan error jelas. Export memakai variasi fallback pertama yang valid dan mencatat error.

**Jawaban:**

## C9 — Compatibility save setelah content berubah — SEBELUM DEMO

Jika variation ID tersimpan sudah dihapus atau scene berubah, apakah Continue ditolak, memakai fallback, atau memulai New Game?

**Saran:** selama jam development, fallback ke variasi default slot dan tampilkan warning. Setelah content freeze, ID tidak boleh diubah.

**Jawaban:**

---

# D. Placer, spawn, dan distribusi content

## D1 — Jenis placer yang diperlukan — BLOCKER

Konfirmasi jenis minimum: enemy, loose loot, breakable/source, environmental creature, story trigger, dan quest/progression placement.

Apakah shop, gate, player spawn, dan RopeAnchor juga dikelola placer atau selalu authored langsung?

**Saran:** random content memakai placer. Shop, gate, story wajib, player spawn, seam, dan RopeAnchor authored langsung dengan ID stabil.

**Jawaban:**

## D2 — Pool berdasarkan scene atau content ID — BLOCKER

Apakah placer menyimpan langsung daftar `PackedScene`, atau ID definition yang dicari melalui catalog?

**Saran:** enemy/loot pool memakai entry Resource berisi content ID, scene, dan weight. Generator tetap tidak mengenal jenis enemy/item tertentu.

**Jawaban:**

## D3 — Spawn chance dan quantity — BLOCKER

Apakah `spawn_chance` menentukan seluruh placer aktif/tidak, lalu quantity di-roll jika aktif? Apakah minimum boleh nol?

**Saran:** chance menentukan activation sekali; jika aktif, quantity berada pada rentang minimum–maximum yang valid. Minimum nol tidak diperlukan karena chance sudah mewakili kosong.

**Jawaban:**

## D4 — Posisi untuk quantity lebih dari satu — BLOCKER

Jika placer menghasilkan beberapa object, di mana masing-masing ditempatkan? Prototype sekarang menumpuk semuanya pada satu marker.

**Saran:** placer memiliki child `SpawnPoint` authored. Quantity tidak boleh melebihi jumlah point; urutan point dipilih deterministik.

**Jawaban:**

## D5 — ID object hasil placer — BLOCKER

Bagaimana ID stabil dibuat ketika satu placer menghasilkan beberapa enemy/item?

**Saran:** gunakan ID turunan yang deterministik, misalnya `placer_id:0`, `placer_id:1`, berdasarkan slot hasil, bukan urutan child runtime.

**Jawaban:**

## D6 — Weighted pool — SEBELUM CONTENT

Apakah weight hanya memilih jenis content, atau juga perlu rarity tier/budget per section?

**Saran:** fondasi pertama hanya membutuhkan integer weight per entry. Tambahkan encounter budget hanya jika content nyata membuktikan random independen buruk.

**Jawaban:**

## D7 — Kepadatan enemy/loot per section — SEBELUM CONTENT

Apakah jumlah placer ditentukan penuh oleh level designer, atau generator mempunyai target density per layer/route?

**Saran:** level designer menentukan marker dan safe zone; generator hanya menentukan isi/chance marker. Jangan membuat procedural density solver.

**Jawaban:**

## D8 — Facing, patrol area, dan formasi enemy — SEBELUM CONTENT

Apakah facing/patrol boundary/formasi merupakan data placer, data scene enemy, atau geometry probe otomatis?

**Saran:** placer/section mengatur facing dan patrol bounds authored. Enemy definition mengatur speed/range umum.

**Jawaban:**

## D9 — Spawn grounding dan collision validation — BLOCKER

Apakah object selalu spawn tepat pada marker authored, atau runtime harus mencari lantai/ruang kosong terdekat?

**Saran:** marker authored wajib valid. Validator memeriksa overlap dan ground; runtime tidak memindahkan content secara diam-diam.

**Jawaban:**

## D10 — Aktivasi enemy di section jauh — BLOCKER

Apakah enemy seluruh layer aktif terus, atau hanya section player dan tetangganya yang diproses?

**Saran:** mulai dengan semua node terinstansiasi tetapi enemy jauh dinonaktifkan melalui section activation. Aktifkan section player dan satu tetangga.

**Jawaban:**

## D11 — Enemy atau loot keluar bounds — SEBELUM CONTENT

Jika enemy jatuh ke jurang/out-of-bounds, apakah dianggap mati permanen, kembali ke placer, atau disimpan di posisi terakhir?

**Saran:** enemy kembali ke safe spawn/placer jika keluar bounds tanpa menerima lethal damage; loot ordinary boleh hilang sesuai aturan item.

**Jawaban:**

## D12 — Required dan quest relic — BLOCKER

Bagaimana generator menjamin quest relic gatekeeper dan item progression wajib muncul serta dapat dicapai?

**Saran:** required content tidak memakai chance. Pilih satu dari daftar marker eligible secara deterministik, lalu validasi tepat satu instance per run.

**Jawaban:**

## D13 — Item langka maksimum satu per run — BLOCKER

Silver Weight direncanakan maksimum satu per run. Apakah generator perlu global unique allocation untuk item seperti ini?

**Saran:** ya. Resolve unique placements pada world level sebelum placer biasa, lalu tandai placer pemenang.

**Jawaban:**

## D14 — Breakable rock dan nested loot — BLOCKER

Apakah breakable relic rock memilih isi saat world generation atau baru melakukan roll ketika dipecahkan?

**Saran:** resolve isi saat generation dan simpan hasilnya. Memecahkan hanya membuka hasil yang sudah ditentukan.

**Jawaban:**

## D15 — Kondisi progression pada placer — SEBELUM CONTENT

Apakah content dapat muncul/hilang setelah whistle, delivery, atau quest berubah dalam run yang sama?

**Saran:** layout dan loot awal tidak berubah setelah generation. Progression hanya membuka gate/story atau mengaktifkan marker yang sejak awal mempunyai hasil tersimpan.

**Jawaban:**

---

# E. Persistence, unloading, dan object dinamis

## E1 — State enemy hidup saat Continue — BLOCKER

Apakah semua enemy hidup menyimpan posisi/health/state, atau hanya enemy penting sementara enemy biasa kembali ke placer dengan health tersisa/default?

Dokumentasi lama mengizinkan reset AI transient; dokumen fondasi menyebut source/enemy state secara umum.

**Saran:** simpan alive/dead dan health untuk semua enemy persisten. Saat Continue, enemy hidup kembali ke placer dalam state aman; jangan simpan chase/attack frame.

**Jawaban:**

## E2 — State placer versus state object — BLOCKER

Apakah save menyimpan hasil placer terpisah dari state object yang dihasilkan?

**Saran:** ya. Placer menyimpan resolved content IDs; setiap child hasil mempunyai stable ID/state sendiri. Destroyed child tidak di-spawn ulang.

**Jawaban:**

## E3 — Parent item dinamis yang menyeberang seam — BLOCKER

Jika thrown/dropped item bergerak dari satu section ke section lain, section mana yang memilikinya untuk save dan unloading?

**Saran:** dynamic world root berada pada layer/world assembly, bukan di bawah section yang dapat dinonaktifkan. Simpan posisi global dan current layer.

**Jawaban:**

## E4 — Rope melintasi seam — BLOCKER

Apakah Rope boleh ditempatkan menyeberangi boundary section?

**Saran:** tidak. RopeAnchor dan seluruh panjang Rope harus berada dalam satu section; validator menolak placement yang melewati bounds.

**Jawaban:**

## E5 — Posisi player yang disimpan — BLOCKER

Selain posisi global, apakah save perlu menyimpan layer, side, slot ID, dan last-safe seam agar recovery tetap benar jika transform world berubah?

**Saran:** simpan posisi global serta semantic location `{layer_id, route_id, slot_id}` dan `last_safe_position`.

**Jawaban:**

## E6 — Waktu autosave saat transisi — BLOCKER

Kapan autosave dilakukan relatif terhadap seam/gate transition dan generation: sebelum pindah, setelah destination siap, atau keduanya?

**Saran:** save setelah destination terinstansiasi, player ditempatkan di safe anchor, dan object persisten terdaftar. Jangan snapshot saat world setengah terbentuk.

**Jawaban:**

## E7 — Section yang tidak aktif — BLOCKER

Jika section jauh dinonaktifkan atau di-unload, apakah timer source/enemy berhenti atau tetap mengikuti waktu dunia?

**Saran:** source tidak respawn sehingga tidak butuh timer. AI section jauh berhenti; effect persisten memakai timestamp/duration saat load jika memang harus terus berjalan.

**Jawaban:**

## E8 — Perubahan scene setelah save dibuat — SEBELUM DEMO

Jika marker atau placer dipindahkan setelah save development dibuat, apakah old save tetap didukung?

**Saran:** sebelum content freeze, save lama boleh dianggap tidak kompatibel setelah perubahan layout besar. Tingkatkan save/world revision dan tampilkan pesan New Game, bukan menebak posisi.

**Jawaban:**

---

# F. Workflow authoring, validation, dan debug

## F1 — Pemilik graybox dan collision — BLOCKER

Siapa yang membuat layout graybox, siapa yang memasang collision, dan bagaimana art team mengganti visual tanpa merusak gameplay?

**Saran:** designer membuat layout pada template; programmer memiliki collision/marker contract; artist mengganti child visual tanpa mengubah root, collision, anchor, atau ID.

**Jawaban:**

## F2 — Teknologi terrain — BLOCKER

Apakah graybox/final terrain menggunakan `TileMapLayer`, `StaticBody2D` dengan shape authored, atau campuran?

**Saran:** gunakan `TileMapLayer` untuk terrain berulang dan collision utama; gunakan scene object untuk platform/hazard/breakable khusus. Jangan membuat runtime mesh terrain.

**Jawaban:**

## F3 — Struktur folder dan naming — SEBELUM GRAYBOX

Konfirmasi pola seperti `world/layer_1/east/slot_01_a.tscn` dan ID `layer1_east_01_a`.

**Saran:** folder berdasarkan layer/route; filename dan ID menyebut slot serta variasi. Scene khusus berada di `world/special/` atau folder lokasi jelas.

**Jawaban:**

## F4 — Template universal atau per-slot — BLOCKER

Apakah tim menduplikasi satu template universal untuk semua section, atau satu template per slot dengan seam/bounds yang sudah dikunci?

**Saran:** buat template per slot setelah macro transforms diputuskan. Variasi selalu diduplikasi dari template slot yang benar.

**Jawaban:**

## F5 — Pemeriksaan validator — BLOCKER

Mana yang wajib menjadi error: ID kosong/duplikat, ukuran salah, anchor hilang, seam berbeda, root placer/dynamic hilang, collision di clearance, spawn overlap, dan camera bounds invalid?

**Saran:** semua hal tersebut error pada development validation. Warning hanya untuk density, safe-zone margin, atau content pool sementara.

**Jawaban:**

## F6 — Validasi seam otomatis — SEBELUM GRAYBOX

Apakah cukup membandingkan anchor/profile, atau validator harus menginstansiasi setiap kombinasi tetangga dan memeriksa collision gap?

**Saran:** lakukan keduanya: pemeriksaan cepat metadata setiap import/test dan matrix scene A/B pada smoke/validation tool.

**Jawaban:**

## F7 — Debug world tools — SEBELUM DEMO

Tool minimum mana yang diinginkan: input seed, regenerate, tampilkan variation ID, tampilkan placer result, teleport ke slot/shop/gate, draw bounds/seam, dan validate world?

**Saran:** buat satu debug panel dengan seed, layout/placer dump, teleport, bounds toggle, dan tombol validator. Regenerate hanya dari New Run agar state tidak tercampur.

**Jawaban:**

## F8 — Preview section terisolasi — SEBELUM GRAYBOX

Apakah setiap section perlu dapat dijalankan sendiri dengan player/test harness, atau hanya diuji melalui assembled world?

**Saran:** sediakan satu `section_test_runner` yang menerima scene section dan spawn player di entry/exit. Jangan menambahkan script test ke setiap section.

**Jawaban:**

## F9 — Scope implementasi world foundation berikutnya — BLOCKER

Untuk tahap setelah questionnaire, apakah target pertama:

1. dua section test tersambung,
2. satu layer lengkap dengan enam slot,
3. shell seluruh 12 slot dengan graybox kosong, atau
4. route demo kecil yang mewakili surface → section → gate?

**Saran:** bangun generator dan validator dengan dua slot nyata, lalu shell seluruh 12 slot menggunakan template graybox. Isi detail dikerjakan setelah kontrak terbukti.

**Jawaban:**

---

# G. Arah level design yang memengaruhi generation

## G1 — Identitas route east dan west — SEBELUM CONTENT

Apakah east/west berbeda dalam difficulty, jenis enemy, loot, terrain, atau hanya variasi layout?

**Saran:** beri identitas sederhana: satu route lebih aman/panjang, satu lebih berbahaya/cepat. Keduanya tetap dapat menyelesaikan progression utama.

**Jawaban:**

## G2 — Difficulty berdasarkan kedalaman — SEBELUM CONTENT

Apakah difficulty meningkat per layer saja, per slot kedalaman, atau juga berdasarkan route?

**Saran:** gunakan tier `{layer, depth_index}`. Route hanya memberi bias content kecil, bukan difficulty tier terpisah.

**Jawaban:**

## G3 — Target waktu traversal — SEBELUM GRAYBOX

Berapa lama target turun satu section, satu layer, dan kembali ke surface tanpa encounter panjang?

Ini dibutuhkan untuk ukuran map, jumlah Rope, autosave 180 detik, dan durasi Numbing Pill.

**Saran:** ukur satu section graybox terlebih dahulu, lalu tetapkan target waktu berdasarkan playtest sebelum memproduksi 12 section.

**Jawaban:**

## G4 — Optional room, secret, dan dead end — SEBELUM GRAYBOX

Apakah section boleh mempunyai cabang/dead end untuk loot, dan apakah generator pernah memilih cabang sebagai pengganti main route?

**Saran:** optional branch berada di dalam authored section. Generator tidak menyusun topology cabang terpisah pada jam build.

**Jawaban:**

## G5 — Informasi map untuk player — NANTI

Apakah game memerlukan minimap/map screen, indikator depth/route, atau player sengaja bernavigasi tanpa map?

**Saran:** untuk demo, tampilkan depth, layer, dan east/west pada HUD/debug; tunda minimap sampai ukuran world terbukti membutuhkannya.

**Jawaban:**

## G6 — Biome dan transisi visual — SEBELUM CONTENT

Apakah pergantian biome terjadi tepat di gate/layer, bertahap antar-slot, atau setiap route mempunyai tema sendiri?

**Saran:** biome utama berubah di ruang gate/layer. Variasi slot memakai palette/props berbeda tanpa mengubah seam atau collision contract.

**Jawaban:**

---

# H. Urutan jawaban yang paling efisien

Jawab dalam urutan berikut agar keputusan berikutnya tidak perlu diulang:

1. **Macro topology:** A1–A8.
2. **Kontrak fisik:** B1–B6, B8, B10, B12, B15.
3. **Generation dan persistence:** C1–C9, E1–E8.
4. **Placer:** D1–D15.
5. **Workflow implementation:** F1–F9.
6. **Level-design tuning:** pertanyaan B/G yang tersisa.

Setelah jawaban diterima, dokumen keputusan world generation harus memperbarui `fondasi_teknis_godot.md`, kontrak programming, dan roadmap implementasi sebelum generator dibuat.
