# Pertanyaan Klarifikasi Fondasi Game

> **Status 7 Agustus 2026:** A1–K2 sudah dijawab dan keputusan yang relevan sudah dipindahkan ke `fondasi_teknis_godot.md`. Dokumen ini dipertahankan sebagai decision history; tidak ada blocker fondasi yang masih terbuka.

Dokumen ini mengumpulkan keputusan desain yang perlu dikunci sebelum fondasi gameplay diimplementasikan. Jawaban tidak harus panjang. Tulis jawaban langsung pada baris **Jawaban:** di bawah setiap pertanyaan.

Prioritas:

- **BLOCKER** — memengaruhi bentuk API atau kepemilikan state; jawab sebelum fondasi terkait dibuat.
- **SEBELUM DEMO** — dapat memakai placeholder sementara, tetapi harus dikunci sebelum demo terintegrasi.
- **NANTI** — tidak menghalangi fondasi; diperlukan sebelum konten terkait dibuat.

## Keputusan yang sudah dipahami

- Multitool adalah item biasa yang memakai inventory dan hotbar seperti item/artifact lain.
- Multitool mempunyai primary action normal, tetapi secondary action-nya bukan throw dan belum ditentukan.
- Akan ada setidaknya satu enemy yang melempar item atau projectile.
- Godot 4.7.1, keyboard/mouse, placeholder asset, viewport internal 640×360, skala 32 px per metre, dan Linux-first tetap menjadi asumsi sampai dikoreksi.

---

# A. Model aksi item dan Multitool

## A1 — Nama dan arti dua tombol item — BLOCKER

Apakah klik kiri/kanan sebaiknya dipahami sebagai **primary action** dan **secondary action** yang ditentukan masing-masing item, bukan aturan global “use” dan “throw”?

Ini penting karena Multitool sudah menjadi pengecualian terhadap aturan klik kanan selalu melempar. Jika setiap item memiliki dua action sendiri, inventory cukup meminta item aktif menjalankan primary/secondary action dan tidak perlu mengenal jenis item.

**Saran:** gunakan `primary_action` dan `secondary_action`. Mayoritas artifact dapat menetapkan secondary action sebagai throw, sedangkan Multitool dapat menggantinya.

**Jawaban:** ya gunakan primary action dan secondary action, karena ada beberapa item yang sedang didesain tidak dapat dilempar

## A2 — Secondary action Multitool — BLOCKER

Apa kandidat fungsi klik kanan Multitool?

Contoh: guard/parry, aim/inspect, charged swing, tool mode, interaction alternatif, atau belum diaktifkan pada prototype.

Kita tidak perlu menentukan animasi/balance sekarang, tetapi perlu mengetahui apakah action tersebut instant, ditahan, diarahkan ke cursor, memiliki cooldown, atau membutuhkan target.

**Saran:** jika belum ada keputusan gameplay, buat secondary action Multitool mengembalikan “belum tersedia” tanpa efek. Jangan membuat sistem mode/charge sebelum fungsi sebenarnya dipilih.

**Jawaban:** belum ditentukan untuk sekarang

## A3 — Arti “item biasa” untuk Multitool — BLOCKER

Manakah aturan item biasa yang juga berlaku untuk Multitool?

- Dapat dipindah antara backpack dan hotbar?
- Dapat dikeluarkan/drop ke dunia?
- Dapat dicuri Tongue Amphibian?
- Dapat dijual?
- Dapat hilang di jurang atau ditinggalkan?
- Dapat ditemukan lebih dari satu atau di-stack?

Dokumen lama menyatakan semuanya dilarang, sedangkan klarifikasi terbaru mengatakan Multitool bertindak seperti item/artifact lain. Ini perlu jawaban eksplisit.

**Saran:** boleh dipindah dan drop, tidak stack, tidak dijual; pencurian/kehilangan hanya diizinkan jika ada cara mendapatkan pengganti di surface.

**Jawaban:**dapat dipindahkan antara backpack/hotbar, dapat dikeluarkan, dapat dicuri (namun hanya jika tidak ada item lain di inventory player), tidak dapat dijual, dapat ditinggalkan di jurang, tidak dapat distack namun dapat dibeli dari shop

## A4 — Kondisi awal dan pengganti Multitool — BLOCKER

Apakah setiap New Game selalu memberi satu Multitool? Jika Multitool hilang atau dicuri, apakah surface shop/service memberikan pengganti gratis, menjual pengganti, atau pemain harus melanjutkan tanpa alat?

Ini menentukan apakah Multitool adalah equipment wajib yang menyamar sebagai item biasa atau benar-benar resource yang dapat hilang.

**Saran:** berikan satu saat New Game dan sediakan pengganti gratis di surface agar run tidak soft-lock.

**Jawaban:**diberikan saat new game, dan dapat dibeli dari shop (diberikan gratis jika hilang pertama kali)

## A5 — Item tanpa secondary action — BLOCKER

Apa yang terjadi jika sebuah item tidak mempunyai secondary action?

Pilihan umumnya: tidak melakukan apa pun dengan feedback, otomatis drop, atau menggunakan fallback throw generik.

**Saran:** tidak ada fallback global. ItemDefinition menyatakan action yang tersedia; input invalid menampilkan feedback singkat. Ini mencegah Multitool atau whistle terlempar akibat asumsi sistem.

**Jawaban:**secara umum, secondary action adalah lempar item jika tidak dikecualikan

## A6 — Action instant, hold, dan release — BLOCKER

Apakah roster final membutuhkan item yang action-nya ditahan lalu dilepas, atau semua action dapat dianggap satu kali tekan?

Holding memengaruhi input contract, control lock, animasi, dan pembatalan saat inventory/pause dibuka. Catalog ide menyebut beberapa hold action, tetapi roster game-jam yang terkunci belum tentu memerlukannya.

**Saran:** untuk roster terkunci saat ini, implementasikan press action saja. Tambahkan begin/hold/release hanya ketika satu item final benar-benar membutuhkannya.

**Jawaban:**untuk saat ini, semua interaction dilakukan dengan press

## A7 — Item aktif saat inventory dibuka — SEBELUM DEMO

Apakah primary/secondary action tetap dapat digunakan ketika inventory overlay terbuka?

Inventory direncanakan memperlambat player tetapi tidak menghentikan dunia. Membolehkan penggunaan item saat overlay terbuka dapat bentrok dengan klik UI.

**Saran:** blok action gameplay ketika cursor berada di UI atau inventory terbuka; player masih dapat bergerak lambat dan menutup inventory.

**Jawaban:**untuk sekarang blok

---

# B. Enemy yang melempar item atau projectile

## B1 — Apa tepatnya yang dilempar enemy? — BLOCKER

Apakah enemy tersebut:

1. menciptakan projectile serangan sementara,
2. melempar item inventory nyata yang dapat diambil player,
3. mengambil item yang sudah ada di dunia lalu melemparkannya, atau
4. dapat melakukan lebih dari satu jenis di atas?

Jawaban ini menentukan apakah kita membutuhkan satu `ThrownItem`, satu `Projectile`, atau keduanya.

**Saran:** pisahkan dua kategori: `ThrownItem` untuk item nyata/recoverable dan `Projectile` untuk serangan sementara. Keduanya berbagi impact payload, bukan satu scene raksasa.

**Jawaban:**1

## B2 — Jenis enemy dan contoh lemparannya — BLOCKER

Enemy mana yang dimaksud, dan apa yang dilemparnya dalam fiction/gameplay?

Contoh yang sudah ada di scope adalah monkey yang melempar batu. Apakah batu monkey sama dengan `Throwable Rock` milik player, atau hanya projectile visual yang hilang setelah impact?

**Saran:** jika monkey dapat menjadi sumber rock untuk player, gunakan item nyata dengan drop chance terbatas. Jika tidak, gunakan projectile sementara agar dunia tidak dipenuhi pickup.

**Jawaban:**mungkin untuk fokus jam ini hanya gunakan projectile sementara

## B3 — Sumber ammunition enemy — BLOCKER

Apakah ammunition enemy terbatas, diambil dari inventory/world, atau tidak terbatas dengan cooldown?

Ammo nyata membutuhkan state, persistence, kemungkinan kehabisan, serta keputusan setelah enemy mati. Ammo tak terbatas hanya membutuhkan cooldown.

**Saran:** ammo tak terbatas dengan cooldown untuk monkey prototype; gunakan item nyata hanya jika mengambil/mencuri ammo adalah bagian penting dari desain.

**Jawaban:**ammo tidak terbatas namun cooldown

## B4 — Dapatkah projectile enemy diambil player? — BLOCKER

Setelah impact, apakah projectile menjadi pickup, pecah, menempel sebagai hazard, atau langsung hilang?

Jika dapat diambil, projectile harus membawa `item_id`, instance state, persistent ID, dan aturan inventory. Jika tidak, ia cukup membawa impact payload dan lifetime.

**Saran:** tentukan per projectile melalui data, tetapi hanya `ThrownItem` yang boleh menjadi pickup.

**Jawaban:**tidak

## B5 — Ownership dan faction — BLOCKER

Siapa yang boleh terkena lemparan?

- Enemy dapat melukai enemy lain?
- Player dapat terkena item yang baru ia lempar setelah memantul?
- Enemy dapat terkena projectile-nya sendiri?
- Neutral creature dapat terkena kedua pihak?

**Saran:** setiap moving payload membawa `source` dan `faction`; abaikan source sampai payload terpisah aman dari collider, lalu gunakan aturan friendly-fire yang dikonfigurasi.

**Jawaban:**enemy dapat melukai enemy yang berbeda, namun tidak ada friendly fire diantara enemy satu jenis

## B6 — Friendly fire enemy — BLOCKER

Apakah friendly fire antar-enemy adalah bagian dari systemic gameplay atau harus dicegah?

Mengizinkannya mendukung tema manipulasi lingkungan, tetapi dapat membuat enemy membersihkan encounter sendiri.

**Saran:** izinkan force/agitation pada semua creature, tetapi damage friendly-fire dapat dikurangi atau ditentukan per attack.

**Jawaban:**enemy dapat terkena damage dari sumber manapun, kecuali friendly fire dari enemy yang jenisnya sama (misal amfibi tidak memiliki friendly fire terhadap sesama amfibi tetapi dapat damage enemy lain)

## B7 — Dampak berdasarkan item atau kecepatan — BLOCKER

Apakah damage/knockback lemparan ditentukan oleh item, kecepatan saat impact, kekuatan pelempar, atau kombinasi ketiganya?

Ini menentukan bentuk `ImpactData` dan apakah enemy dan player memakai formula yang sama.

**Saran:** `base_damage` dan `mass` berasal dari payload, lalu velocity menghasilkan multiplier yang di-clamp. Thrower hanya menentukan initial velocity.

**Jawaban:**`base_damage` dan `mass` berasal dari payload, lalu velocity menghasilkan multiplier yang di-clamp. Thrower hanya menentukan initial velocity.

## B8 — Satu atau beberapa target per lemparan — BLOCKER

Apakah payload berhenti/pecah pada target pertama, dapat menembus beberapa target, atau dapat memantul dan mengenai ulang?

**Saran:** default berhenti pada collision valid pertama. Penetration/bounce menjadi behavior khusus karena membutuhkan hit-history agar satu target tidak terkena berulang setiap frame.

**Jawaban:**kebanyakan projectile berhenti pada collision valid pertama, namun item seperti silver weight dapat hit multiple enemies

## B9 — Collision antar-projectile/item — SEBELUM DEMO

Apakah projectile dapat bertabrakan dengan projectile atau thrown item lain?

Ini memungkinkan interaksi seperti menembak jatuh projectile, tetapi menambah collision noise dan risiko physics yang sulit dibaca.

**Saran:** nonaktifkan collision antar-moving-payload untuk prototype; aktifkan hanya untuk artifact yang secara khusus menangkap/mendorong projectile.

**Jawaban:**jangan dulu untuk sekarang

## B10 — Interaksi dengan terrain — BLOCKER

Setelah menyentuh terrain, apakah payload memantul, menancap, pecah, berhenti menjadi pickup, atau hilang?

Terrain tidak destructible, tetapi impact masih dapat memicu hazard atau agitate creature/environment.

**Saran:** sediakan enum kecil per payload: `STOP`, `BOUNCE`, `STICK`, `BREAK`, `DISAPPEAR`.

**Jawaban:**akan ditentukan per payload. lanjutkan sesuai saran

## B11 — Aiming dan telegraph enemy — SEBELUM DEMO

Apakah enemy membidik posisi player saat melempar, memprediksi gerakan, atau memakai arah tetap? Berapa lama telegraph harus terlihat sebelum projectile aktif?

**Saran:** bidik posisi player saat telegraph dimulai tanpa prediction; projectile harus tetap dapat dihindari jika player bereaksi.

**Jawaban:**  bidik posisi player saat telegraph dimulai tanpa prediction

## B12 — Status effect dari projectile — BLOCKER

Apakah projectile menggunakan contract impact yang sama untuk damage, force, slow, poison, bleed, agitation, dan theft?

**Saran:** satu `ImpactData` boleh membawa damage, impulse, dan daftar status; theft tetap behavior khusus karena memindahkan ownership item.

**Jawaban:**sesuai saran

---

# C. Inventory, item state, dan item di dunia

## C1 — Tujuan hotbar dan backpack — BLOCKER

Apakah dua hotbar slot terpisah dari lima backpack slot, atau hotbar hanya menunjuk dua item yang sebenarnya tetap berada di backpack?

Model terpisah berarti total tujuh slot. Model reference berarti total lima item dengan dua shortcut.

**Saran:** gunakan tujuh slot terpisah sesuai dokumen lama: lima backpack dan dua hotbar. Click-to-swap memindahkan stack, bukan membuat reference kedua.

**Jawaban:**terpisah

## C2 — Pickup masuk ke slot mana — BLOCKER

Saat item diambil, apakah sistem mengisi stack yang cocok, hotbar kosong, backpack kosong, atau selalu backpack terlebih dahulu?

**Saran:** gabungkan stack kompatibel terlebih dahulu, lalu backpack kosong. Hotbar hanya berubah atas tindakan player agar item aktif tidak tiba-tiba terganti.

**Jawaban:**gabungkan stack kompatibel dulu, lalu hotbar jika kosong, lalu backpack kosong

## C3 — Item dengan state dan stacking — BLOCKER

Bagaimana item seperti Silver Weight rusak atau Lantern Snail aktif disimpan di inventory?

Pilihan aman adalah hanya item tanpa state/ber-state identik yang boleh stack. Namun snail tenang direncanakan dapat stack delapan sementara snail aktif perlu instance terpisah.

**Saran:** item stateful aktif otomatis dipisah menjadi quantity satu; versi default/tenang boleh stack.

**Jawaban:**sesuai saran

## C4 — Drop manual — BLOCKER

Karena secondary action tidak selalu throw, bagaimana player mengeluarkan item dari inventory tanpa mengaktifkannya?

Pilihan: tombol Drop terpisah, action pada inventory UI, atau item tertentu sama sekali tidak dapat di-drop.

**Saran:** tombol/context action `Drop` di inventory UI. Jangan memakai fallback klik kanan karena klik kanan milik behavior item.

**Jawaban:**karena throw secondary action berdasarkan force seberapa jauh jarak cursor dan player, drop dapat dilakukan dengan throw namun jarak cursor dekat dengan player. secondary action throw hanya melempar, jika ingin mengaktifkan harus menggunakan primary action terlebih dahulu lalu throw. untuk dari inventory gunakan action drop

## C5 — Item jatuh ke area tidak terjangkau — BLOCKER

Apa yang terjadi jika item penting jatuh ke jurang, keluar bounds, atau terjebak collision?

**Saran:** ordinary item boleh hilang; whistle dan item progression memakai last-safe-position atau layanan pengganti. Jangan teleport semua item karena menghapus risiko melempar.

**Jawaban:**item boleh hilang, important item boleh hilang karena ada metode untuk recover

## C6 — Pencurian item oleh Tongue Amphibian — BLOCKER

Apakah frog mencuri seluruh stack atau satu unit? Apakah ia memilih hotbar, backpack, atau item aktif terlebih dahulu? Apakah Multitool valid?

**Saran:** curi satu unit ordinary item dengan prioritas item aktif, lalu hotbar, lalu backpack; pindahkan instance yang sama ke carried world item. Jangan curi Multitool sampai replacement rule A4 jelas.

**Jawaban:**sesuai saran. whistle dapat dicuri jika itu adalah item terakhir yang dimiliki player, dan multitool dapat dicuri jika itu adalah item terakhir selain whistle yang ada di player

## C7 — Mengambil kembali item curian — SEBELUM DEMO

Apakah player harus membunuh frog, memukul dengan Multitool, membuatnya menjatuhkan karena startled, atau cukup menyentuh item?

**Saran:** satu hit/impact membuat frog menjatuhkan item tanpa harus mati. Ini sesuai desain player lemah dan memakai contract force/agitation.

**Jawaban:**sesuai saran

## C8 — Living item — BLOCKER

Saat Lantern Snail berubah dari creature menjadi inventory item dan kembali ke dunia, state apa yang bertahan: health, agitation, scream cooldown, light state, dan posisi?

**Saran:** simpan agitation/cooldown saja; reset AI transient state dan health kecuali melukai snail memang bagian desain.

**Jawaban:**sesuai saran, namun karena snail hanya memiliki 2 damage snail hanya dapat diambil sekali. mengambil snail dilakukan dengan menggunakan multitool yang mengurangi health snail 1, namun nilai itu tidak disimpan. jika player menggunakan snail itu lagi di world, snail akan spawn dengan 1 health dan akan mati jika player mencoba mengambil lagi


## tambahan: tiap item memiliki weight value tertentu yang dapat mempengaruhi mobilitas player (movement speed & gravity untuk lompat)

---

# D. Combat, damage, dan physical reaction

## D1 — Enemy yang dapat dibunuh — BLOCKER

Apakah semua enemy memiliki health dan dapat dibunuh, atau beberapa hanya dapat dihindari/didorong/di-stun?

**Saran:** semua target memakai reaction contract yang sama, tetapi `damageable` dan `killable` adalah flags terpisah. Gatekeeper/large threat dapat menerima impact tanpa harus bisa dibunuh.

**Jawaban:**sesuai saran, namun semua enemy dapat dibunuh jika health habis

## D2 — Contact damage — BLOCKER

Apakah menyentuh tubuh enemy selalu memberi damage, hanya ketika enemy menyerang, atau berbeda per enemy?

**Saran:** jangan beri contact damage global. Damage hanya berasal dari hitbox attack yang aktif agar feedback dan telegraph jelas.

**Jawaban:**sesuai saran

## D3 — Invulnerability setelah terkena hit — BLOCKER

Apakah player/enemy mempunyai invulnerability singkat setelah damage? Apakah force tetap berlaku selama invulnerability?

**Saran:** player mendapat i-frame singkat untuk damage tetapi tetap menerima force. Nilai akhir dapat di-tune di Inspector.

**Jawaban:**sesuai saran

## D4 — Damage jatuh dan out-of-bounds — SEBELUM DEMO

Apakah jatuh jauh memberi damage, langsung mati, atau hanya mengembalikan player ke titik aman?

Ini penting karena Layer 2 berfokus pada knockback.

**Saran:** fall damage berdasarkan kecepatan dengan cap; out-of-bounds mengembalikan ke safe marker dan memberi damage besar, bukan kehilangan kontrol permanen.

**Jawaban:** fall damage memberi damage, oob mengembalikan player ke titik spawn di layer 0 namun health player dikurangi hingga menjadi hanya 1

## D5 — Damage membatalkan action — BLOCKER

Apakah damage membatalkan item wind-up, healing Bandage, climbing, dan interaction?

**Saran:** hit membatalkan wind-up dan interaction; Bandage healing-over-time tetap berjalan seperti rekomendasi dokumen lama kecuali playtest terlalu aman.

**Jawaban:**hit tidak membatalkan apapun

## D6 — Definisi small enemy untuk Silver Weight — NANTI

Apakah `small` adalah kategori ukuran fisik, tag khusus per enemy, atau berdasarkan health/mass?

**Saran:** tag eksplisit `small_enemy`; jangan menebak dari sprite, collision, atau health.

**Jawaban:**tag explisit, karena small enemy adalah semua enemy kecuali big roamer type dan boss type

---

# E. Sound, sight, dan target priority

## E1 — Sound menembus terrain — BLOCKER

Apakah sound memakai radius lurus yang menembus dinding, berkurang ketika terhalang, atau membutuhkan jalur terbuka?

**Saran:** untuk jam, radius lurus tanpa pathfinding/occlusion. Perbedaan jenis dan priority tetap ada; tambahkan occlusion hanya jika playtest terasa tidak masuk akal.

**Jawaban:**sesuai saran

## E2 — Makna sound priority — BLOCKER

Jika enemy mendengar beberapa sound, apakah priority selalu menang, lalu jarak; atau sound terbaru selalu mengganti target?

**Saran:** pilih priority tertinggi, lalu sound terbaru, lalu jarak terdekat. Setiap enemy dapat mempunyai minimum priority dan reaction profile.

**Jawaban:**sesuai saran

## E3 — Hushcap dan penglihatan player — BLOCKER

Apakah Hushcap hanya memblokir sight AI, juga menggelapkan pandangan player, atau benar-benar menjadi occluder fisik untuk raycast?

**Saran:** Area2D cloud menandai line-of-sight sebagai blocked dan memakai overlay semi-transparan untuk player; tidak mengubah collision fisik.

**Jawaban:**sesuai saran 

## E4 — Prioritas spider mark vs Lantern Snail — BLOCKER

Jika flyer sedang mengejar marked player lalu snail berteriak, target mana yang menang dan berapa lama?

**Saran:** spider mark mempunyai priority lebih tinggi; snail hanya mengambil alih jika mark habis atau target tidak valid.

**Jawaban:**sesuai saran

## E5 — Kehilangan target — SEBELUM DEMO

Setelah sight/sound target hilang, apakah enemy langsung kembali patrol, mencari di last-known position, atau tetap mengejar selama timer?

**Saran:** datangi last-known position, tunggu singkat, lalu kembali. Gunakan timer per enemy definition.

**Jawaban:**sesuai saran

---

# F. World, run, dan persistence

## F1 — Konfirmasi ukuran dunia — BLOCKER

Apakah keputusan berikut benar: viewport internal 640×360, 32 px/metre, setiap east/west section 640×1600, tiga section per side per layer, dan rope 160 px?

**Saran:** kunci ini sebelum art/collision/section dibuat agar tidak ada rescale massal.

**Jawaban awal:** asset yang sudah dibuat adalah item 16×16 px; ukuran map saat itu masih sementara.

**Revisi playtest 7 Agustus 2026:** viewport tetap 640×360 dan skala tetap 32 px/metre, tetapi setiap east/west section menjadi 1280×1600 px. Tiga section tetap disusun vertikal per sisi; total layer 2560×4800 px.

**Revisi playtest 8 Agustus 2026:** tinggi section dibagi dua menjadi 800 px. Kontrak authoring map sekarang 1280×800 px per section dan 2560×2400 px per layer.

## F2 — East/west route — BLOCKER

Apakah sisi east dan west adalah dua rute vertikal terpisah yang hanya terhubung di titik tertentu, atau satu area selebar 1280 px yang bebas diseberangi?

Ini mengubah section contract, seam anchors, camera bounds, dan cara generator menyusun scene.

**Saran revisi:** dua kolom section 1280 px yang dapat mempunyai authored connector. Jangan mengasumsikan koneksi pada setiap ketinggian.

**Jawaban:**east/west route terpisah, dan dapat diakses melalui gate di layer 0

## F3 — Persistent ordinary dropped items — BLOCKER

Apakah semua item yang dijatuhkan/dilempar dan masih berada di dunia harus tersimpan saat Continue, atau hanya item unik/penting?

Menyimpan semuanya akurat tetapi dapat memperbesar save dan menuntut stable runtime ID untuk setiap batu.

**Saran:** simpan item bernilai/unik dan item yang ditandai persistent; ordinary rock/projectile boleh dibersihkan saat load.

**Jawaban:**sesuai saran, namun semua item yang berasal dari player harus tersimpan (walaupun ordinary rock)

## F4 — Enemy respawn selama living run — BLOCKER

Apakah enemy mati tetap mati sampai run berakhir, respawn setelah kembali ke surface, atau respawn berdasarkan waktu?

**Saran:** enemy placer tetap kosong selama living run; reset hanya saat death/New Game. Ini paling konsisten dengan persistent world yang direncanakan.

**Jawaban:**sesuai dengan saran

## F5 — Item source respawn — BLOCKER

Apakah plant, breakable rock, resin tree, dan snail yang sudah dipanen tetap kosong selama living run?

**Saran:** ya, kosong sampai run berikutnya. Shop menjadi sumber supply yang dapat diprediksi.

**Jawaban:**sesuai saran

## F6 — Save saat projectile sedang terbang — BLOCKER

Jika autosave terjadi ketika item/projectile berada di udara, apakah disimpan sebagai airborne state, dijatuhkan aman ke terrain, dikembalikan ke inventory, atau diabaikan?

**Saran:** transient projectile diabaikan; persistent `ThrownItem` disimpan setelah berhenti. Saat save, item yang masih terbang dikembalikan ke last-safe state/owner agar tidak hilang atau terduplikasi.

**Jawaban:**sesuai saran

## F7 — Pause dan inventory terhadap waktu dunia — BLOCKER

Konfirmasi: pause menghentikan seluruh SceneTree, sedangkan inventory hanya memperlambat player dan enemy/status/timer tetap berjalan normal?

**Saran:** ya. Jangan memakai global `time_scale` untuk inventory.

**Jawaban:**ya

## F8 — Checkpoint/safe recovery — SEBELUM DEMO

Apakah ada checkpoint dalam layer, atau hanya surface dan Layer 2 shop sebagai safe recovery point?

**Saran:** simpan `last_safe_position` ketika masuk surface/shop/section seam valid. Gunakan hanya untuk recovery out-of-bounds/load, bukan respawn setelah mati.

**Jawaban:**tidak ada titik checkpoint, namun saat save&continue player ada di posisi mereka sebelumnya. namun sebagai fallback, ikuti sesuai saran

---

# G. Economy, progression, dan gate

## G1 — Delivery count dan stack — BLOCKER

Apakah menjual stack berisi delapan relic menambah delivery sebesar delapan unit atau satu stack?

**Saran:** hitung setiap unit. UI harus menampilkan progress sebelum transaksi dikonfirmasi.

**Jawaban:**hitung setiap unit, balancing akan dilakukan nanti, dan beberapa item memiliki value delivery berbeda

## G2 — Menjual item dari hotbar — BLOCKER

Apakah shop dapat menjual langsung dari backpack dan hotbar, atau player harus memindahkannya ke backpack dahulu?

**Saran:** tampilkan kedua container dan minta konfirmasi; jangan menjual active item melalui satu klik.

**Jawaban:**sesuai saran

## G3 — Multitool dan item wajib di shop — BLOCKER

Jika Multitool benar-benar item biasa, apakah shop dapat membelinya? Bagaimana dengan whistle, rope, supply, dan Throwable Rock?

**Saran:** `sellable` menjadi data per item. Multitool dan whistle false; relic mengikuti nilai; supply/rock tidak dijual pada build jam.

**Jawaban:**sesuai saran

## G4 — Blue Whistle setelah hilang — SEBELUM DEMO

Jika frog mencuri whistle lalu player kembali ke surface, apakah pengganti mempertahankan tier Blue atau kembali Red?

**Saran:** tier progression tersimpan terpisah dari item fisik; service memberi pengganti sesuai tier tertinggi yang sudah diperoleh.

**Jawaban:**sesuai saran

## G5 — Final gatekeeper pass condition — NANTI

Apa satu kondisi wajib untuk melewati final gatekeeper dan menerima Moon Whistle?

**Saran:** gunakan kondisi yang sudah didukung shared system—whistle/item delivery/dialogue—bukan boss framework baru.

**Jawaban:**final gatekeeper menggunakan mekanik yang sama seharusnya, namun sistem boss final akan berbeda

---

# H. Keputusan item yang memengaruhi fondasi

## H1 — Throw untuk supply — BLOCKER

Bandage, Rope, Info Book, dan Numbing Pill mempunyai secondary action apa? Apakah masing-masing dapat dilempar/drop sebagai world item atau secondary action-nya disabled?

**Saran:** secondary disabled untuk item yang tidak mempunyai efek throw; drop dilakukan dari inventory UI. Rope tetap memakai primary placement.

**Jawaban:**secondary function akan kami tentukan sesuai playtest, usahakan implementasi secondary function dapat dilakukan dengan mudah

## H2 — Rattlepod setelah kosong — SEBELUM DEMO

Apakah Rattlepod kosong menghilang, menjadi pickup tanpa nilai, atau dapat diisi ulang?

**Saran:** satu pod mengeluarkan tiga pulsa lalu menghilang. Tidak perlu persistent partial charge untuk prototype.

**Jawaban:** satu rattlepod hanya dapat digunakan sekali lalu menghilang

## H3 — Penggunaan Rattlepod dari stack — SEBELUM DEMO

Apakah satu primary action mengaktifkan seluruh tiga pulsa dan mengonsumsi satu pod, atau setiap klik menghabiskan satu charge pada instance yang sama?

Pilihan kedua membuat satu stack mengandung pod penuh dan pod parsial sehingga model state lebih kompleks.

**Saran:** satu action = tiga pulsa = konsumsi satu unit.

**Jawaban:**primary action mengaktifkan rattlepod selama 5 detik, dimana sound constant clattering akan bermain, namun akan membuat efek targeting terhadap enemy setiap detik (5 kali total)

## H4 — Numbing Pill kedua — NANTI

Apakah penggunaan kedua me-refresh timer, menambah durasi, atau ditolak selama masih aktif? Apakah pill menghapus curse stack lama?

**Saran:** refresh ke durasi penuh dan hanya mencegah curse baru; tidak menghapus stack lama.

**Jawaban:**tiap numbing pill menambah 5 menit

## H5 — Silver Weight setelah lemparan pertama — NANTI

Apakah item durability satu masih bernilai penuh, bernilai lebih rendah, atau tidak dapat dijual?

**Saran:** nilai jual turun berdasarkan durability agar state instance memiliki konsekuensi ekonomi yang jelas.

**Jawaban:**sesuai saran

## H6 — Throwable Rock recovery — SEBELUM DEMO

Kapan rock menjadi pickup kembali: segera setelah collision, setelah diam, atau hanya pada jenis terrain tertentu? Apakah rock pecah pada impact keras?

**Saran:** menjadi pickup setelah kecepatan rendah selama waktu singkat; hilang jika keluar bounds. Tidak perlu durability pada prototype.

**Jawaban:**sesuai saran

## H7 — Damage membatalkan Bandage — NANTI

Apakah menerima damage membatalkan healing-over-time Bandage?

**Saran:** tidak untuk prototype; ubah hanya jika playtest membuat healing terlalu aman.

**Jawaban:**sesuai saran

## H8 — Driftseed pada target — NANTI

Target apa yang valid: player, small enemy, flyer, item, projectile, atau semuanya? Apakah effect dapat ditumpuk?

**Saran:** whitelist player, small enemy, dan loose item; refresh duration tanpa stack.

**Jawaban:**driftseed untuk player dan boss gatekeeper

---

# I. UI, control, dan presentasi

## I1 — Konfirmasi control map — BLOCKER

Apakah kontrol berikut diterima: A/D atau panah untuk gerak, Space lompat, E interaksi, Tab inventory, 1/2 atau scroll pilih hotbar, klik kiri primary, klik kanan secondary, Esc pause?

**Jawaban:**ya

## I2 — Interaksi dan Multitool — BLOCKER

Apakah `E` selalu melakukan interaksi umum, sementara klik kiri Multitool melakukan swing/tool use? Atau seluruh interaksi batu/snail harus hanya melalui Multitool?

**Saran:** `E` untuk pickup/shop/gate/dialogue; Multitool primary untuk breakable rock, harvest snail, dan melee hit.

**Jawaban:**sesuai saran

## I3 — Aim indicator — SEBELUM DEMO

Apakah semua secondary throw memerlukan garis lintasan, hanya arah/kekuatan sederhana, atau tanpa preview?

**Saran:** tampilkan garis pendek arah dan kekuatan; ballistic arc penuh ditunda kecuali lemparan sulit dibaca.

**Jawaban:**dotted line pendek arah dan kekuatan

## I4 — Mouse di inventory — BLOCKER

Apakah click-to-swap memakai klik kiri untuk memilih/memindah dan klik kanan untuk context action/drop? Bagaimana cara membatalkan selection?

**Saran:** klik kiri pilih lalu swap; klik kanan membuka action kecil; Esc/Tab atau klik slot terpilih membatalkan.

**Jawaban:**sesuai saran

## I5 — Controller support — NANTI

Apakah controller tetap di luar scope jam?

**Saran:** ya. Tetap gunakan Input Map agar controller dapat ditambahkan kemudian tanpa mengubah gameplay code.

**Jawaban:**sesuai saran

---

# J. Urutan jawaban dan implementasi

Jawab lebih dahulu:

1. A1–A6: bentuk item action dan status Multitool.
2. B1–B8, B10, B12: perbedaan thrown item dan enemy projectile.
3. C1–C6: ownership dan pemindahan item.
4. D1–D3, E1–E4: shared reaction API.
5. F1–F7: world dan persistence boundary.
6. G1–G3, H1, I1–I2, I4: aturan yang disentuh banyak sistem.

Pertanyaan berlabel **SEBELUM DEMO** dan **NANTI** boleh dijawab setelah blocker, selama jawaban sementara tidak dimasukkan sebagai aturan permanen ke foundation.

---

# K. Klarifikasi progression yang sudah dijawab

## K1 — Batas playable build setelah Layer 2

Apakah jam build mempunyai Layer 3 yang benar-benar dapat dimasuki dan dimainkan, atau build berakhir setelah player mencapai/melewati gate menuju Layer 3?

Ini menentukan apakah world contract tetap dua layer atau harus menyediakan slot/section Layer 3.

**Jawaban:** build berakhir ketika player mencapai entrance Layer 3; Layer 3 tidak playable pada jam build

## K2 — Powerful relic dan Moon Whistle

Apakah powerful relic yang diberikan gatekeeper Layer 2 shop adalah Moon Whistle, menggantikan Moon Whistle sebagai progression reward, atau merupakan item berbeda yang digunakan sebelum Moon Whistle diperoleh?

Ini menentukan whistle progression, ending trigger, inventory category, dan reward UI.

**Jawaban:** powerful relic adalah item terpisah; gatekeeper memberikan item tersebut bersama Moon Whistle sebelum perjalanan menuju gate Layer 3
