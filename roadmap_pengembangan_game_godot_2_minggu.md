# Roadmap Pengembangan Game Jam

## Tujuan Dokumen

Dokumen ini adalah roadmap produksi untuk build game jam saat ini. Dokumen ini menggantikan rencana lama yang berbasis fase dan mengasumsikan waktu tiga minggu.

Tim harus menggunakan dokumen ini sebagai papan tugas bersama. Pekerjaan diatur berdasarkan **aspek**, bukan ditugaskan secara permanen kepada Programmer A atau Programmer B. Developer boleh mengambil aspek siap kerja apa pun yang sesuai dengan minatnya, tetapi setiap tugas yang diambil harus memiliki satu penanggung jawab aktif dan titik integrasi yang jelas.

Roadmap ini mengasumsikan:

- Dua programmer
- Satu project lead yang dapat membantu programming
- Kontributor art dan audio terpisah
- Total empat belas hari kalender
- Godot 4.x
- Keyboard dan mouse sebagai skema kontrol wajib
- Feature freeze tetap yang dimulai pada Hari 11

---

# 1. Aturan Produksi

## 1.1 Label Prioritas

- **P0 — Wajib:** Run yang direncanakan tidak dapat diselesaikan atau dipresentasikan tanpa fitur ini.
- **P1 — Penting:** Sangat meningkatkan pengalaman yang direncanakan, tetapi dapat disederhanakan jika pekerjaan P0 terlambat.
- **P2 — Tambahan:** Hanya dikerjakan setelah game lengkap berhasil ditamatkan melalui build hasil export.

Pekerjaan P1 atau P2 tidak boleh menunda perbaikan integrasi P0 yang rusak.

## 1.2 Kepemilikan Tugas

Developer bebas memilih pekerjaannya dengan aturan berikut:

1. Ambil satu tugas dengan batas yang jelas pada satu waktu.
2. Catat penanggung jawab, hasil yang diharapkan, dan file yang kemungkinan akan berubah.
3. Hindari dua orang mengedit scene `.tscn` yang sama secara bersamaan.
4. Utamakan child scene, script, dan Resource terpisah daripada mengedit main scene bersama.
5. Integrasikan pekerjaan ke build yang dapat dimainkan pada hari yang sama ketika fungsinya mulai bekerja.
6. Tugas belum selesai hanya karena bekerja secara terpisah; uji penerimaannya harus lulus di game utama.
7. Jika terblokir lebih dari satu jam, laporkan penghambatnya dan ambil tugas siap kerja lainnya.

## 1.3 Definisi Selesai

Sebuah fitur baru dianggap selesai jika:

- Bekerja di build hasil export, bukan hanya di editor.
- Tidak menghasilkan error berulang di debugger.
- Menggunakan art placeholder dengan aman jika art final belum tersedia.
- Mendukung pause, perpindahan scene, kematian, `New Game`, dan `Continue` jika relevan.
- Datanya dapat diatur tanpa menulis ulang script lain yang tidak terkait.
- Uji penerimaannya sudah dijalankan.
- Sudah diuji satu kali oleh anggota tim lain.

## 1.4 Batas Scope

Build game jam **tidak** memerlukan:

- Terrain yang dapat dihancurkan
- Pembuatan terrain secara prosedural
- Editor behavior tree umum
- Statistik equipment yang kompleks
- Crafting
- Dialog bercabang
- Layer ketiga yang dapat dimainkan
- Dukungan controller kecuali semua pekerjaan P0 selesai
- Beberapa slot save
- Lokalisasi
- Fitur online
- Menu aksesibilitas tingkat lanjut
- Fase boss yang rumit
- Item atau musuh di luar daftar dalam dokumen ini

`Moon Whistle` adalah hadiah penamat; Layer 3 tidak dapat dimainkan.

---

# 2. Pengalaman Pemain yang Dituju: Dari Boot hingga Menutup Game

Build lengkap harus mendukung urutan berikut.

## 2.1 Boot

1. File executable terbuka tanpa editor Godot.
2. Splash singkat studio/tim bersifat opsional dan dapat dilewati.
3. Main menu tampil dengan:
   - `New Game`
   - `Continue`, hanya aktif jika ada run hidup
   - `Controls`
   - `Credits`
   - `Quit`
4. Jika autosave tidak valid, `Continue` dinonaktifkan dan game tetap dapat digunakan.

## 2.2 New Game

1. Jika masih ada run hidup, `New Game` meminta konfirmasi sebelum menggantinya.
2. Run dan dunia saat ini di-reset.
3. Pengetahuan item yang sudah dipelajari tetap disimpan.
4. Seed baru dibuat.
5. World generator memilih variasi section dan menentukan hasil placer secara deterministik.
6. Pemain mulai di permukaan dengan:
   - 100 health
   - 50g
   - `Red Whistle` di slot whistle khusus
   - Multitool
   - Backpack dan hotbar kosong selain equipment awal wajib
7. Intro pendek berupa text bubble yang dapat dilanjutkan pemain diputar.

## 2.3 Loop Run Hidup

1. Membeli persediaan di toko permukaan.
2. Turun ke Layer 1.
3. Menjelajahi rute timur atau barat melalui section buatan tangan.
4. Menemukan, mengenali, menggunakan, membawa, atau mengorbankan relic.
5. Menghindari, memanipulasi, atau melawan makhluk.
6. Memasang tali yang bertahan selama run tersebut.
7. Naik dan mengalami kutukan Layer 1.
8. Menjual relic di permukaan dan meningkatkan jumlah pengiriman.
9. Pada batas pengiriman yang dikonfigurasi—saat ini 10 unit item—mengganti `Red Whistle` dengan `Blue Whistle`.
10. Melewati atau mengakali senior diver secara kreatif di gerbang Layer 1.
11. Masuk ke Layer 2 dan melintasi kanopi hutan terbalik.
12. Mencapai toko aman di pertengahan Layer 2.
13. Melanjutkan perjalanan melalui wilayah hippo di bagian bawah Layer 2.
14. Melewati gatekeeper terakhir Layer 2.
15. Menerima `Moon Whistle` dan menampilkan ending game jam.

Run berlanjut melalui perjalanan pulang ke permukaan dan beberapa kali penyelaman. Run hanya berakhir ketika pemain mati atau pemain sengaja memulai `New Game`.

## 2.4 Pause, Autosave, dan Menutup Game

- Autosave setiap 180 detik selama run hidup.
- Autosave juga dilakukan setelah progres besar, transaksi toko, masuk ke layer, kembali ke permukaan, dan memilih `Return to Menu`.
- Pause menu berisi:
  - `Resume`
  - `Controls`
  - `Return to Menu`
  - `Quit to Desktop`
- `Return to Menu` dan `Quit to Desktop` harus meminta save sebelum meninggalkan gameplay.
- Permintaan menutup dari sistem operasi harus mencoba melakukan satu save terakhir, tetapi autosave tiga menit tetap menjadi perlindungan terhadap penghentian paksa.
- `Continue` memulihkan run, seed, section yang terpilih, perubahan dunia, kondisi pemain, toko, progres, dan pengetahuan yang sama.

## 2.5 Kematian

1. Hentikan input pemain dan ancaman aktif.
2. Evaluasi jumlah penggunaan artifact selama run.
3. Tambahkan deskripsi yang baru dipelajari ke pengetahuan permanen.
4. Hapus save run hidup dan nonaktifkan `Continue`.
5. Tampilkan layar kematian yang mencantumkan relic yang baru dipelajari.
6. Tawarkan `New Game` dan `Main Menu`.
7. Memulai `New Game` me-reset uang, inventory, dunia, tali, toko, musuh, progres whistle, dan seed, tetapi mempertahankan pengetahuan.

## 2.6 Ending

1. Pemain melewati gatekeeper terakhir Layer 2.
2. Urutan text bubble pendek diputar.
3. `Moon Whistle` menggantikan `Blue Whistle`.
4. Layar ending mengonfirmasi penyelesaian dan menampilkan credit atau pesan penutup singkat.
5. Pemain dapat kembali ke main menu atau keluar.

---

# 3. Referensi Desain yang Sudah Ditetapkan

## 3.1 Tata Letak Dunia

- Hub permukaan dan toko permukaan
- Layer 1: kedalaman 150 meter
- Layer 2: kedalaman 150 meter
- Gerbang Layer 1 pada kedalaman 150 meter
- Toko Layer 2 sekitar kedalaman 225 meter, di pertengahan Layer 2
- Gatekeeper terakhir Layer 2 sekitar kedalaman 300 meter

Setiap layer memiliki:

- Sisi timur dan barat
- Tiga slot section vertikal di setiap sisi yang tersambung tanpa transisi
- Dua variasi buatan tangan untuk setiap slot
- Enam section terpilih per layer untuk setiap seed
- Dua belas scene section buatan tangan per layer
- Target penuh dua puluh empat scene section untuk kedua layer

Generator tidak membuat terrain. Generator memilih satu variasi buatan tangan untuk setiap slot tetap, membuat instance pada posisi tetap, lalu mengaktifkan placer di dalamnya.

### Urutan pembuatan konten yang aman untuk game jam

1. Buat graybox satu variasi valid untuk seluruh dua belas slot wajib di kedua layer.
2. Pastikan seluruh rute dari permukaan sampai ending dapat dimainkan.
3. Buat variasi kedua untuk setiap slot.
4. Jika waktu kurang, gunakan kembali atau ubah tampilan ringan dari variasi yang sudah selesai daripada membiarkan sambungan rusak.

## 3.2 Pemain dan Inventory

- Health dasar: 100
- Lima slot backpack
- Dua slot hotbar
- Batas stack: 8 unit untuk item yang sama
- Whistle menggunakan slot khusus dan dapat saling menggantikan.
- Membuka inventory:
  - Memperlambat pemain
  - Menutupi bagian tengah layar
  - Menggelapkan bagian layar lainnya
- Klik kiri menggunakan item hotbar aktif.
- Klik kanan melempar item aktif.
- Arah lemparan mengikuti posisi cursor.
- Kekuatan lemparan didasarkan pada jarak cursor, dibatasi oleh nilai minimum dan maksimum yang dapat diatur.
- Multitool melakukan interaksi jarak dekat, memecahkan batu relic, mengambil Lantern Snail, dan memberikan damage jarak dekat yang rendah.
- Pertarungan langsung memungkinkan, tetapi sengaja dibuat lemah dibandingkan penggunaan relic dan penghindaran.

## 3.3 Ekonomi dan Toko

Uang awal: 50g.

### Toko permukaan

- Membeli relic seharga 100% nilai dasar.
- Menjual unit item menambah progres pengiriman untuk `Blue Whistle`.
- Menjual persediaan standar.
- Stock dapat dibuat tanpa batas untuk kesederhanaan game jam, kecuali item tertentu memerlukan batas.

### Toko Layer 2

- Merupakan area aman.
- Membeli relic seharga 75% nilai di permukaan.
- Gunakan `round(base_value * 0.75)` untuk harga integer kecuali playtest menentukan aturan lain.
- Memiliki stock terbatas yang dikonfigurasi manual.
- Jumlah stock bertahan sepanjang run dan setelah `Continue`.
- Tidak perlu dihitung untuk progres `Blue Whistle` karena pemain sudah melewati gerbang Layer 1.

### Nilai progres yang dapat diatur

- Batas awal `Blue Whistle` adalah 10 unit item yang dikirim.
- Apakah unit dalam satu stack dihitung satu per satu tetap menjadi variabel playtest, bukan logika hardcoded.
- Semua harga dan jumlah stock toko harus dapat diedit melalui Resource atau field Inspector.

## 3.4 Daftar Item

| Item | Sumber atau Harga | Kegunaan | Nilai Jual | Catatan Persistence |
| --- | --- | --- | ---: | --- |
| Rope | Toko permukaan, 20g | Memasang tali panjat sekitar lima meter; dikonsumsi dan tidak dapat diambil kembali | Bukan relic untuk dijual | Tali terpasang bertahan selama run dan harus tersimpan |
| Red Whistle | `New Game` | Kredensial Layer 1 | — | Slot khusus; dapat diganti di permukaan |
| Blue Whistle | Hadiah setelah batas pengiriman | Melewati senior diver Layer 1 | — | Menggantikan Red Whistle |
| Moon Whistle | Hadiah akhir Layer 2 | Hadiah ending | — | Menggantikan Blue Whistle |
| Multitool | Equipment awal | Memecahkan batu, mengambil snail, interaksi dekat, serangan lemah | — | Tool awal |
| Bandage | Toko permukaan, 50g | Menghentikan bleed dan memulihkan 50 health secara perlahan, dipengaruhi penalti healing | — | Consumable |
| Info Book | Toko permukaan, 30g | Langsung membuka semua deskripsi item | — | Pengetahuan bertahan setelah New Game |
| Numbing Pill | Toko permukaan, 120g | Menekan kutukan saat naik selama sekitar lima menit | — | Consumable; durasi harus tersimpan |
| Sun Sphere | Relic umum Layer 1 | Penerangan berdurasi pendek saat dilempar | 20g | Consumable |
| Throwable Rock | Dari batu relic yang dipecahkan | Damage lempar dasar dan interaksi fisik | Tidak dapat dijual | Dapat diambil kembali atau tidak ditentukan oleh hasil collision |
| Lantern Snail | Gua dan Layer 2 | Cahaya portabel; agitasi menyebabkan teriakan, dazzle, dan menarik musuh besar | 50g | Diambil dengan multitool |
| Rattlepod | Area tebing | Membuat suara di posisi pemain atau titik lemparan | 30g | Pulsa terbatas atau perilaku consumable |
| Hushcap | Pintu masuk gua | Membuat awan yang menghalangi pandangan di pemain atau titik benturan | 30g | Biasanya dikonsumsi |
| Cling Resin | Pohon di Layer 1–2 | Membuat area lengket yang memperlambat body dan projectile yang valid | 50g | Wadah dikonsumsi saat digunakan |
| Driftseed | Pohon di Layer 1–2 | Mengurangi gravitasi dan meningkatkan kerentanan knockback pada target | 30g | Durasi dan aturan pengambilan kembali berbasis data |
| Silver Weight | Langka, maksimal satu per run | Membuat pemegang menjadi berat; lemparan membunuh monster kecil; pecah setelah dua lemparan | 150g | Durability dan posisi dunia harus tersimpan |

## 3.5 Aturan Pengetahuan

- Setiap relic memiliki flag permanen untuk pengetahuan deskripsinya.
- Relic yang belum dikenal mengandalkan petunjuk visual dan eksperimen pemain.
- Setiap relic memiliki batas penggunaan kecil per run.
- Saat mati, relic yang mencapai batas penggunaan menjadi dikenal secara permanen.
- Progres penggunaan parsial tidak dibawa ke run berikutnya.
- `Info Book` langsung menandai seluruh deskripsi relic sebagai sudah dikenal.
- Pengetahuan disimpan terpisah dari run hidup agar `New Game` tidak menghapusnya.

## 3.6 Daftar Musuh Layer 1

| Musuh | Perilaku Wajib | Sistem Bersama |
| --- | --- | --- |
| Amphibian berlidah panjang | Menembakkan lidah, mencuri item, memperlambat pemain selama satu detik, dan kabur membawa item; hanya dapat mencuri whistle jika tidak ada item inventory lain | Serangan jarak jauh, pencurian inventory, pengambilan kembali item |
| Burung knockback | Menyambar dan memberikan knockback; serangan beberapa burung dalam jendela waktu tertentu menyebabkan damage | Flying mover, jendela serangan kelompok |
| Thorn bloom | Diam di tempat; melepaskan jarum saat terganggu; jarum bertahan beberapa menit, memberikan damage dan bleed | Agitasi, projectile, hazard persisten |
| Lantern Snail | Memberikan cahaya; menjerit dan menyebabkan dazzle saat terganggu; menarik flyer besar; dapat diambil | Cahaya, agitasi, sound event, interaksi pengambilan |
| Spider gua | Menembakkan projectile pelambat, memberikan damage kecil, menyebabkan total 25 poison damage selama 10 detik, dan menandai pemain agar dikejar flyer | Serangan jarak jauh, slow, poison, target mark |
| Flyer besar Layer 1 | Satu ancaman besar di ruang terbuka pada sisi tempat pemain berada; mengejar berdasarkan line of sight; serangan memberikan 75 damage | Flying chase, pemeriksaan halangan, target override |
| Senior diver gatekeeper | Menjaga pintu masuk Layer 2; melewatkan pemegang Blue Whistle; jika tidak, bergerak lambat dan menyerang cepat; dapat dilawan atau diakali dengan relic | Kondisi dialog/gerbang, pertarungan darat, reaksi target |

## 3.7 Daftar Musuh Layer 2

| Musuh | Perilaku Wajib | Sistem Bersama |
| --- | --- | --- |
| Kelompok monyet | Menjaga jarak, melempar batu, berpindah menjauhi pemain, bergerak dalam kelompok kecil; damage dan knockback kecil | State machine ranged-kiting, jarak antarkelompok |
| Burung knockback kuat | Menggunakan ulang fondasi burung Layer 1 dengan knockback lebih kuat atau waktu serangan lebih ketat | Scene burung dengan data profile Layer 2 |
| Flyer kecil Layer 2 | Beberapa aktif sekaligus; menyebar; menargetkan pemain ketika terlihat; setiap serangan memberikan 25 damage | Flying chase, separation steering, target berdasarkan sight |
| Hippo penyeruduk | Layer 2 bagian bawah; charge dengan telegraph; memberikan 50 damage, knockback besar, dan incapacitation satu detik | State machine ground charge, efek stun |
| Gatekeeper terakhir | Menghalangi rute ending; wajib memiliki satu syarat pasti untuk lewat; keberhasilan memberikan Moon Whistle | Kondisi gerbang, dialog, trigger ending |

Gatekeeper terakhir tidak memerlukan beberapa fase boss. Project lead harus menetapkan satu syarat wajib untuk melewatinya paling lambat akhir Hari 2. Bypass kreatif atau solusi pertarungan adalah P1 kecuali dapat menggunakan sistem yang sudah ada dengan sedikit pekerjaan tambahan.

## 3.8 Kutukan Saat Naik

Sistem kutukan melacak referensi kedalaman menggunakan koordinat dunia, bukan resolusi viewport.

- Catat posisi terdalam yang sudah dicapai.
- Bergerak naik sejauh satu jarak tinggi layar yang dikonfigurasi dari referensi tersebut menerapkan paket kutukan layer saat ini.
- Jika pemain cukup diam selama 10 detik, reset referensi ke kedalaman saat ini.
- Bergerak turun memperbarui posisi terdalam dan tidak menerapkan kutukan.
- `Numbing Pill` menekan penerapan kutukan selama sekitar lima menit.

### Paket Layer 1

- Perubahan warna layar
- Perubahan acak pada kecepatan gerak maksimum
- Healing berkurang
- Jarak lempar maksimum berkurang secara acak

### Paket Layer 2

- Tambahkan satu stack batas health untuk setiap penerapan kutukan.
- Setiap stack mengurangi health maksimum yang dapat dipulihkan sebesar 10% dari maximum health dasar.
- Batasi pengurangan pada 50%, sehingga setidaknya 50 health masih dapat dipulihkan.
- Hentikan pemain secara acak selama 0,5 detik.
- Terapkan perubahan warna layar.
- Kurangi jarak lempar maksimum.

Semua rentang, durasi, probabilitas, warna, dan multiplier harus berada dalam Resource `CurseProfile` per layer. Project lead harus menetapkan nilai prototype yang dapat digunakan paling lambat akhir Hari 3.

## 3.9 Scope Cerita

Cerita disampaikan melalui text bubble sederhana yang dilanjutkan oleh pemain.

Urutan wajib:

- Intro `New Game`
- Penjelasan toko permukaan atau penyelaman pertama
- Pemberian `Blue Whistle`
- Interaksi gerbang senior diver
- Sapaan toko Layer 2
- Interaksi gatekeeper terakhir
- Ending `Moon Whistle`
- Ringkasan kematian/pengetahuan baru

Dialog bercabang tidak diperlukan. Portrait, efek typewriter, voice acting, pilihan, dan lokalisasi merupakan P2.

---

# 4. Arsitektur Project Godot

Arsitektur harus membuat penambahan konten dapat diprediksi tanpa berkembang menjadi framework besar.

## 4.1 Struktur Folder yang Disarankan

```text
res://
  autoload/
  core/
  data/
    items/
    enemies/
    effects/
    shops/
    dialogue/
  player/
  items/
    behaviors/
    world/
  enemies/
    shared/
    layer_1/
    layer_2/
  world/
    surface/
    layer_1/
    layer_2/
    placers/
    generation/
  ui/
  audio/
  art/
  debug/
  tests/
```

Jangan berulang kali mengatur ulang folder setelah integrasi konten dimulai.

## 4.2 Autoload Minimal

Gunakan tidak lebih dari berikut ini kecuali muncul kebutuhan yang jelas:

- `GameSession`: kondisi run saat ini, progres, seed, uang, whistle, pengiriman, dan signal tingkat tinggi.
- `SaveManager`: meta save, run save, timer autosave, validasi, penulisan atomic, dan urutan load.
- `ContentCatalog`: lookup Resource item, musuh, effect, toko, dan dialog berdasarkan ID stabil.
- `SceneRouter`: transisi main menu/gameplay dan transition overlay.
- `AudioManager` bersifat opsional; gunakan hanya jika kontrol volume/music bersama memerlukannya.

Logika gameplay harus tetap berada dalam scene dan component, bukan menumpuk di Autoload.

## 4.3 ID Stabil

Setiap object persisten memerlukan ID stabil yang terlihat dan ditetapkan secara manual:

- Slot section: `layer1_east_02`
- Variasi section: `layer1_east_02_b`
- Placer: `layer1_east_02_b_loot_03`
- Rope: ID run unik yang dibuat saat dipasang
- Story trigger: `story_blue_whistle_award`

Mengganti nama node tidak boleh diam-diam mengubah identitas persistence-nya.

Tambahkan validator debug yang melaporkan persistent ID duplikat atau kosong ketika dunia dimuat.

## 4.4 Data Resource

### `ItemDefinition`

Field wajib:

- ID item stabil
- Nama tampilan
- Deskripsi belum dikenal dan sudah dikenal
- Icon dan world sprite
- Maximum stack size
- Nilai jual di permukaan
- Harga beli, jika ada
- Batas penggunaan untuk discovery
- Aturan consumable/retrievable
- Behavior Resource atau behavior scene
- Hook audio dan VFX

### `EnemyDefinition`

Field wajib:

- ID musuh stabil
- Scene
- Maximum health
- Contact damage atau attack damage
- Kekuatan knockback
- Nilai movement
- Jarak detection
- Ketersediaan layer
- Aturan persistence
- Hook audio dan VFX

Script khusus musuh dapat mengekspos nilai tuning tambahan. Jangan paksa semua perilaku masuk ke satu Resource yang sangat besar.

### `EffectDefinition`

- ID effect stabil
- Durasi
- Aturan stack
- Maximum stack
- Perilaku tick
- Icon/warna UI
- Aturan save

### `ShopDefinition`

- ID toko
- Multiplier harga beli
- ID item stock dan jumlahnya
- Apakah stock terbatas
- Apakah penjualan dihitung sebagai progres pengiriman

### `DialogueSequence`

- ID sequence
- Urutan baris teks
- Nama speaker opsional
- Portrait opsional
- Apakah gameplay dihentikan sementara
- Apakah penyelesaiannya persisten

## 4.5 Interface Behavior Item

Gunakan satu inventory generik dan satu scene item lempar generik.

Setiap behavior item khusus hanya perlu mengekspos hal yang dibutuhkannya:

- `can_use(context) -> bool`
- `use(context) -> UseResult`
- `can_throw(context) -> bool`
- `on_thrown(thrown_item, context)`
- `on_impact(thrown_item, collision)`
- `capture_state() -> Dictionary` ketika memiliki kondisi persisten
- `restore_state(data)` ketika memiliki kondisi persisten

`ThrownItem` generik mengatur trajectory, collision, kelayakan pickup, dan identitas dunia persisten. Behavior mengatur hasil unik seperti cahaya, suara, spore, resin, perubahan gravitasi, atau durability `Silver Weight`.

## 4.6 Fondasi Musuh

Gunakan component bersama yang kecil dan state machine sederhana per musuh. Jangan membuat behavior tree.

Node/script bersama yang disarankan:

- Health dan damage receiver
- Hitbox/hurtbox
- Knockback receiver
- Status receiver
- Sight detector menggunakan raycast
- Listener sound event
- Helper navigation/ground probe
- Target ketertarikan pada item
- Adapter persistent state

Method reaksi yang disarankan:

- `hear_sound(event)`
- `apply_force(vector)`
- `apply_slow(amount, duration)`
- `set_target_override(target, duration)`
- `become_agitated(source)`
- `receive_thrown_item(item, impact)`

Setiap musuh menggunakan enum state kecil yang eksplisit, seperti `IDLE`, `PATROL`, `AIM`, `ATTACK`, `RECOVER`, `CHASE`, atau `FLEE`. Hanya implementasikan state yang diperlukan musuh tersebut.

## 4.7 Pembuatan Dunia dan Placer Deterministik

Langkah pembuatan dunia:

1. Baca seed run.
2. Untuk setiap dua belas slot section tetap, pilih variasi A atau B menggunakan stream RNG deterministik.
3. Buat instance scene terpilih pada transform slot yang tetap.
4. Validasi anchor masuk dan keluar yang seamless.
5. Tentukan hasil setiap placer menggunakan seed turunan dari `run_seed + persistent_id`.
6. Periksa saved state sebelum men-spawn apa pun.
7. Daftarkan object persisten ke `SaveManager`.

Enemy placer dan loot placer memerlukan:

- Persistent ID stabil
- Peluang spawn
- Weighted content pool
- Rentang jumlah untuk loot
- Kondisi layer/progres opsional
- Hasil deterministik
- Pemeriksaan status sudah diambil/dikalahkan

Memuat ulang seed yang sama tidak boleh melakukan roll ulang pada placer.

## 4.8 Arsitektur Save

Gunakan dua file save secara logis.

### Meta save

- Versi save
- ID deskripsi item yang sudah dikenal
- Settings yang diperlukan di luar run

### Save run hidup

- Versi save dan flag run aktif
- Seed run
- Variasi section terpilih
- Posisi pemain, sisi, layer, health, dan effect aktif
- Uang
- Backpack, hotbar, jumlah item, dan state instance item
- Whistle saat ini
- Jumlah pengiriman dan flag progres
- Sisa waktu `Numbing Pill`
- Posisi referensi kutukan dan stack batas health Layer 2
- Stock toko permukaan dan Layer 2
- ID loot yang dikumpulkan dan sumber yang dipanen
- ID musuh yang dikalahkan
- Runtime state untuk musuh hidup penting bila diperlukan
- Posisi dan ID rope yang dipasang
- Posisi dan durability item persisten yang dijatuhkan/dapat diambil kembali
- ID story trigger yang selesai
- State gatekeeper

Projectile sementara, cloud singkat, dan kondisi combat satu frame tidak perlu disimpan. Saat `Continue`, tutup UI sementara dan pulihkan pemain dalam kondisi kontrol netral yang aman.

Penulisan harus menggunakan file sementara lalu menggantikan file lama agar gangguan tidak merusak save valid sebelumnya.

---

# 5. Paket Kerja Berdasarkan Aspek

Developer dapat mengambil paket kerja apa pun yang dependency-nya sudah terpenuhi.

## A. Boot Project, Menu, dan Export — P0

### Tujuan

Membuat game dapat boot, berpindah scene, pause, dan ditutup secara andal.

### Tugas

- Buat project settings dan Input Map.
- Buat main menu, panel controls, panel credits, pause menu, death screen, dan ending screen.
- Implementasikan transisi `SceneRouter`.
- Implementasikan konfirmasi `New Game` ketika masih ada run hidup.
- Aktifkan `Continue` hanya jika save run hidup valid.
- Tangani permintaan menutup dari sistem operasi melalui `SaveManager`.
- Konfigurasikan ukuran window, stretch mode, perilaku mouse, dan export preset.
- Hasilkan build export pada Hari 1 dan setidaknya sekali setiap hari sesudahnya.

### Input dan output

- Memanggil `GameSession.start_new_run()` dan `SaveManager.load_run()`.
- Gameplay scene mengirim permintaan kembali ke menu, kematian, dan ending.
- Tidak mengedit state inventory, dunia, atau musuh secara langsung.

### Uji penerimaan

- Boot bersih mencapai menu.
- `New Game` mencapai permukaan.
- Pause menghentikan gameplay dan resume bekerja dengan benar.
- `Return to Menu` menyimpan dan mengaktifkan `Continue`.
- `Quit` bekerja di build hasil export.
- Save tidak valid tidak membuat menu crash.

## B. Siklus Run, Autosave, dan Persistence — P0

### Tujuan

Menjaga satu dunia hidup tetap stabil sampai pemain mati atau sengaja memulai `New Game`.

### Tugas

- Implementasikan schema meta save dan run save dengan nomor versi.
- Implementasikan timer autosave 180 detik.
- Implementasikan event save di toko, transisi layer, perubahan progres, kembali ke menu, dan keluar.
- Tambahkan API registrasi untuk object persisten.
- Simpan dan pulihkan pemain, dunia, inventory, toko, gerbang, dialog, rope, dan state instance item.
- Saat mati, pindahkan hanya pengetahuan yang baru dipelajari ke meta save dan batalkan run hidup.
- Saat `New Game`, pertahankan meta knowledge dan reset semua hal lainnya.
- Tambahkan atomic write dan fallback untuk save tidak valid.
- Tambahkan aksi debug untuk force save, force load, clear run, dan clear semua data.

### Dependency

- Membutuhkan Dictionary state yang disepakati dari aspek lainnya.
- Dapat dimulai dengan Dictionary placeholder sebelum konten tersedia.

### Uji penerimaan

- Tutup game setelah mengambil item; `Continue` mempertahankan item dan tidak men-spawn ulang sumbernya.
- `Continue` mempertahankan variasi section terpilih.
- Rope terpasang kembali pada posisi yang sama.
- Durability dan posisi dunia `Silver Weight` bertahan setelah `Continue`.
- Stock toko dan uang bertahan setelah `Continue`.
- Kematian menghapus `Continue` tetapi mempertahankan deskripsi yang dipelajari.
- `New Game` menghasilkan seed baru dan `Red Whistle`.

## C. Player Controller, Camera, Damage, dan Interaction — P0

### Tujuan

Membuat controller anak yang andal dan mendukung pergerakan hati-hati, bukan pertarungan kuat.

### Tugas

- Gerak horizontal, acceleration, deceleration, jump, fall, slope, dan one-way platform jika digunakan.
- Camera follow melewati section vertikal tanpa transisi dengan look-ahead yang masuk akal.
- Health, damage, hit protection singkat, knockback, incapacitation, dan signal kematian.
- Serangan multitool jarak pendek dan ray/area interaksi.
- Interaction prompt untuk toko, sumber item, gerbang, story trigger, dan item yang dapat diambil kembali.
- Control lock untuk inventory, dialog, stun, pause, ending, dan kematian.
- Hook untuk animation, footsteps, hit flash, camera shake, dan suara.
- Expose nilai movement dan damage untuk tuning.

### Kontrak interface

- Sistem status mengubah movement/healing/throwing melalui modifier bernama.
- Inventory meminta pemain menggunakan atau melempar item terpilih.
- Musuh memanggil satu API damage, bukan mengedit health secara langsung.

### Uji penerimaan

- Pemain dapat melintasi section graybox ke bawah dan ke atas.
- Knockback tidak dapat mendorong pemain menembus terrain.
- Stun hippo satu detik menonaktifkan input lalu selalu mengembalikan kontrol.
- Inventory dan dialog tidak pernah membuat movement terkunci permanen.
- Kematian hanya terpicu sekali.

## D. Inventory, Hotbar, Throwing, dan Discovery — P0

### Tujuan

Mendukung gameplay berfokus item dengan kompleksitas UI minimum.

### Tugas

- Lima slot backpack dan dua slot hotbar.
- Maximum stack delapan.
- Menambah, mengurangi, split hanya bila diperlukan, memindahkan antara backpack/hotbar, memilih slot aktif, dan menolak inventory penuh.
- Overlay inventory yang memperlambat pemain, menutupi tengah layar, dan menggelapkan bagian lain.
- Pickup dan drop item generik.
- Penggunaan dengan klik kiri dan lemparan dengan klik kanan.
- Kekuatan lempar berdasarkan jarak cursor dengan batas yang dapat diatur.
- Scene item lempar generik dengan collision, impact, retrieval, consumption, dan state instance persisten.
- Slot whistle khusus dan alur penggantian whistle.
- Jumlah penggunaan artifact per run dan lookup deskripsi yang dikenal permanen.
- Behavior `Info Book` untuk membuka semua deskripsi.
- Feedback jelas untuk inventory penuh, item tidak dapat digunakan, item habis, dan deskripsi baru yang dikenal.

### Uji penerimaan

- Item menumpuk sampai delapan dan overflow ditangani dengan aman.
- Membuka inventory menciptakan bahaya yang direncanakan dan dapat ditutup dengan benar.
- Arah dan kekuatan lemparan konsisten pada ukuran window berbeda.
- Item lempar tidak terduplikasi setelah pickup atau `Continue`.
- Item tidak dikenal menampilkan deskripsi tidak dikenal; item dikenal menampilkan teks lengkap.
- Pencurian frog tidak pernah memilih whistle selama ada item inventory lain.

## E. Behavior Item dan Sumber Lingkungan — P0

### Tujuan

Mengimplementasikan seluruh item yang terdaftar melalui fondasi bersama.

### Urutan implementasi P0

1. Multitool dan batu relic yang dapat dipecahkan
2. Throwable Rock
3. Rope
4. Bandage
5. Sun Sphere
6. Rattlepod
7. Hushcap
8. Cling Resin
9. Driftseed
10. Lantern Snail dan pengambilannya
11. Numbing Pill
12. Durability Silver Weight dan kill monster kecil
13. Info Book
14. Definisi whistle

### Tugas sumber lingkungan

- Batu relic yang dapat dipecahkan dapat membuka relic placer dan juga menghasilkan batu lempar.
- Node pertumbuhan Rattlepod dan Hushcap hanya dapat dipanen sekali per run.
- Node pohon Resin hanya dapat dipanen sekali per run.
- Node pohon Driftseed hanya dapat dipanen sekali per run.
- Mengambil Lantern Snail memerlukan multitool dan mengubah makhluk menjadi item tanpa memperlakukannya sebagai drop hasil kill.
- Musuh tidak menjatuhkan relic ketika mati.

### Uji penerimaan

- Setiap item dapat diberikan melalui debug UI, diambil, digunakan, dilempar bila sesuai, dijual bila sesuai, dan disimpan.
- Setiap artifact memengaruhi pemain, musuh, atau dunia melalui API reaksi bersama dan sebisa mungkin bukan hardcode khusus musuh.
- Silver Weight hanya membunuh musuh dengan tag small, bertahan setelah satu lemparan, dan pecah pada lemparan kedua.
- Bandage menghentikan bleed dan memulihkan total 50 health secara perlahan sebelum modifier.
- Durasi Numbing Pill bertahan setelah `Continue`.

## F. Penyusunan Dunia, Section, Placer, dan Rope — P0

### Tujuan

Membangun dunia authored berbasis seed tanpa geometry prosedural.

### Tugas

- Buat marker slot tetap untuk sisi timur/barat dan tiga posisi per layer.
- Tetapkan kontrak scene section: ukuran, origin, anchor masuk, anchor keluar, collision bounds, camera bounds, parent placer, dan parent object dinamis.
- Buat pemilihan A/B deterministik dari seed run.
- Implementasikan enemy placer dan loot placer dengan ID stabil, peluang, dan weighted pool.
- Bangun hub permukaan, gerbang Layer 1, ruang toko pertengahan Layer 2, dan ruang gerbang terakhir.
- Buat satu variasi graybox untuk setiap slot wajib sebelum membuat variasi kedua.
- Tambahkan validasi pemasangan rope dan behavior rope yang dapat dipanjat.
- Simpan rope yang dipasang dan cegah pengambilan kembali.
- Validasi bahwa rute timur dan barat tersambung dari permukaan sampai ending.

### Uji penerimaan

- Seed yang sama menghasilkan dua belas section terpilih dan hasil placer yang sama.
- Seed berbeda dapat memilih variasi berbeda.
- Setiap seam terpilih dapat dilintasi tanpa celah collision.
- Sebuah section dapat diganti tanpa mengubah kode world generator.
- Hasil placer tidak di-roll ulang setelah `Continue`.
- Rope bertahan sampai kematian atau `New Game`.

## G. Framework Musuh dan Konten Layer 1 — P0

### Tujuan

Membuat kontrak musuh bersama dan seluruh ancaman Layer 1.

### Urutan yang disarankan

1. Component bersama untuk damage, hitbox, knockback, sight, sound, status, dan persistence
2. Burung knockback
3. Amphibian berlidah dan pencurian item
4. Thorn bloom dan jarum persisten
5. State makhluk Lantern Snail
6. Projectile spider, poison, dan tracking mark
7. Flyer besar dan pengejaran berbasis obstruction
8. Senior diver gatekeeper

### Catatan implementasi

- Damage kelompok burung harus memakai satu jendela recent-hit bersama pada pemain.
- Item yang dicuri menjadi world item yang dapat diambil kembali dan dibawa amphibian.
- Amphibian hanya memilih whistle jika tidak ada item inventory biasa.
- Masa hidup jarum dapat diatur dan tidak wajib bertahan setelah `Continue` jika penyimpanannya terlalu mahal; bersihkan jarum sementara dengan aman saat load.
- Flyer harus menggunakan raycast atau pemeriksaan obstruction dan tidak dapat menyerang menembus terrain solid.
- Tracking mark dari spider meminta prioritas target flyer melalui signal target override bersama.
- Senior diver menggunakan state machine sederhana dan memeriksa slot whistle melalui interaksi gerbang.

### Uji penerimaan

- Setiap musuh bekerja di test arena khusus dan satu section asli.
- Setiap musuh bereaksi terhadap suara, force, slow, obstruction, atau agitasi bila sesuai.
- Tidak ada musuh yang memerlukan perubahan khusus pada sistem inventory.
- Satu perjalanan turun dan naik Layer 1 dapat diselesaikan tanpa pertarungan.
- Blue Whistle memungkinkan pemain melewati gerbang.

## H. Musuh Layer 2 dan Gatekeeper Terakhir — P0

### Tujuan

Membuat Layer 2 menjadi ancaman traversal berbasis knockback dengan memanfaatkan fondasi yang sudah ada.

### Tugas

- AI ranged-kiting monyet dengan jarak kelompok dan batu lempar.
- Burung Layer 2 sebagai variasi data dari burung yang sudah ada.
- Kelompok flyer kecil menggunakan flying chase bersama dan separation.
- State hippo: idle/patrol, telegraph, charge, collision, recovery.
- Serangan hippo memberikan 50 damage, knockback besar, dan incapacitation satu detik.
- Interaksi gatekeeper terakhir dan satu syarat pasti untuk lewat.
- Pemberian Moon Whistle dan signal ending.

### Aturan scope

Gatekeeper terakhir boleh menggunakan kembali component senior diver. Jangan membuat framework boss rumit kedua. Syarat untuk lewat harus ditetapkan pada Hari 2 dan berfungsi pada Hari 9.

### Uji penerimaan

- Monyet menjaga jarak tanpa berjalan keluar dari permukaan kanopi yang direncanakan.
- Kelompok flyer menyebar sehingga tidak menjadi satu gumpalan sprite bertumpuk.
- Charge hippo terlihat jelas sebelum berbahaya.
- Knockback tidak dapat membuat pemain terdampar permanen di luar level bounds.
- Rute dari toko Layer 2 ke ending dapat diselesaikan.
- Melewati gatekeeper terakhir memberikan Moon Whistle tepat satu kali.

## I. Status Effect dan Kutukan Saat Naik — P0

### Tujuan

Hanya mendukung status yang diperlukan konten saat ini dan membuat proses naik mudah dipahami.

### Status wajib

- Bleed
- Poison: total 25 damage selama 10 detik
- Slow
- Incapacitation satu detik
- Tracking mark spider
- Penekanan kutukan oleh Numbing Pill
- Modifier gravitasi/knockback Driftseed
- Modifier kutukan Layer 1
- Stack batas health Layer 2

### Tugas

- Implementasikan add, refresh, stack, tick, remove, save, dan signal UI untuk effect.
- Implementasikan satu tracker jarak kutukan yang dapat dikonfigurasi dan tidak bergantung pada resolusi layar.
- Implementasikan reset referensi setelah pemain diam 10 detik.
- Implementasikan Resource `CurseProfile` Layer 1 dan Layer 2.
- Terapkan healing melalui satu function yang mematuhi multiplier healing dan batas Layer 2.
- Terapkan lemparan melalui satu function yang mematuhi modifier jarak.
- Pastikan penekanan oleh pill menghentikan penerapan kutukan baru tanpa merusak referensi kedalaman.
- Tambahkan feedback yang mudah dibaca untuk progres poison, bleed, stun, tracking, durasi pill, dan penerapan kutukan.

### Uji penerimaan

- Poison memberikan tepat total 25 damage selama 10 detik dalam kondisi normal.
- Bandage menghentikan bleed, tetapi tidak menghentikan poison.
- Batas health Layer 2 tidak pernah turun di bawah 50 health.
- Diam selama 10 detik me-reset referensi kutukan sesuai desain.
- Bergerak turun tidak sengaja memicu kutukan.
- Save/Continue mempertahankan effect persisten dan me-reset stun sementara dengan aman.

## J. Toko, Uang, Progres Pengiriman, dan Gerbang — P0

### Tujuan

Menyelesaikan loop ekonomi dan progres whistle.

### Tugas

- Tampilan uang dan API transaksi.
- UI beli/jual toko permukaan.
- Toko Layer 2 dengan stock terbatas dan harga beli 75%.
- Nilai jual item dibaca dari `ItemDefinition`.
- Jumlah pengiriman permukaan diperbarui berdasarkan aturan unit item yang dapat dikonfigurasi.
- Event batas Blue Whistle dan text bubble.
- Penggantian whistle dan layanan whistle pengganti di permukaan.
- Pemeriksaan Blue Whistle oleh senior diver.
- State penyelesaian gatekeeper terakhir dan pemberian Moon Whistle.
- Simpan semua state uang, stock, pengiriman, dan gerbang.

### Uji penerimaan

- Pemain mulai dengan 50g dan tidak dapat membeli tanpa uang cukup.
- Penjualan di permukaan menggunakan nilai penuh.
- Penjualan di Layer 2 menggunakan nilai 75% yang dibulatkan.
- Stock terbatas tidak dapat dibeli dua kali setelah habis atau setelah `Continue`.
- Batas pengiriman dapat diatur tanpa mengubah kode toko.
- Blue dan Moon Whistle diberikan sekali dan menggantikan whistle saat ini.

## K. HUD, UI Inventory, Dialog, dan Feedback — P0

### Tujuan

Membuat semua aturan penting dapat dipahami oleh audiens game jam yang baru pertama kali bermain.

### HUD wajib

- Health dan batas healing yang berkurang
- Uang
- Dua slot hotbar dengan jumlah dan pilihan aktif
- Overlay backpack/inventory
- Slot whistle
- Icon status aktif atau teks ringkas
- Sisa durasi Numbing Pill
- Progres pengiriman sebelum Blue Whistle
- Interaction prompt
- Indikator autosave

### Tugas sistem dialog

- Resource `DialogueSequence` dan scene bubble yang dapat digunakan ulang.
- Input advance, skip/advance cepat, nama speaker, dan portrait opsional.
- Gameplay lock selama dialog wajib aktif.
- Dukungan trigger satu kali yang persisten.
- Urutan wajib dari Bagian 3.9.

### Tugas feedback

- Damage flash dan arah damage
- Indikasi knockback/stun
- Pemberitahuan inventory penuh
- Feedback pickup/use/throw item
- Tampilan deskripsi belum dikenal dan sudah dikenal
- Awal kutukan dan modifier aktif
- Hasil transaksi toko
- Penolakan atau keberhasilan gerbang
- Pengetahuan yang baru dipelajari saat mati

### Uji penerimaan

- Anggota audiens baru dapat menemukan kontrol tanpa penjelasan developer.
- Text bubble tidak pernah mengunci pemain secara permanen.
- UI tetap dapat dibaca saat perubahan warna layar dan efek Hushcap aktif.
- Bahaya membuka inventory terlihat tetapi tidak menutupi kontrol inventory sendiri.
- Ending dan death screen selalu menerima input.

## L. Integrasi Art, Animation, Audio, dan Presentasi — P1 setelah placeholder

### Tujuan

Memungkinkan kontributor bekerja mandiri tanpa menghambat kode.

### Kontrak asset

- Programmer menyediakan scene placeholder dan nama animation wajib lebih awal.
- Artist mengirim sprite dengan scale dan konvensi pivot/origin yang disepakati.
- Collision shape tetap menjadi tanggung jawab programmer kecuali dikoordinasikan secara eksplisit.
- Scene musuh mengekspos state animation: idle, move, telegraph, attack, hit, dan death sesuai kebutuhan.
- Item memerlukan icon inventory, world sprite, dan sprite lempar opsional.
- Asset UI mendukung nine-patch scaling bila sesuai.
- File audio menggunakan nama event stabil, bukan dipanggil langsung dari script yang tidak terkait.

### Audio wajib

- Confirm/cancel menu
- Movement dan landing pemain
- Penggunaan multitool
- Pickup, penggunaan, lemparan, dan pecahnya item
- Damage pemain, healing, poison, bleed, dan kutukan
- Telegraph dan serangan musuh
- Teriakan Lantern Snail
- Transaksi toko
- Pemberian whistle/progres
- Cue ending

### Keamanan dan keterbacaan

- Hindari flash satu layar penuh yang terlalu keras.
- Pastikan perubahan warna layar, Hushcap, dan dazzle snail dapat bertumpuk tanpa membuat game sepenuhnya tidak terlihat.
- Pastikan telegraph serangan terlihat jelas pada latar meadow maupun inverted forest.

## M. Debug Tools, QA, Balance, dan Build — P0

### Tujuan

Membuat seluruh game dapat diuji dalam hitungan menit tanpa memerlukan run panjang berulang kali.

### Debug tools

- Memilih atau menampilkan seed
- Teleport ke permukaan, setiap slot section, kedua toko, kedua gerbang, dan ending
- Memberikan item apa pun dan menetapkan jumlahnya
- Menetapkan uang
- Menetapkan jumlah pengiriman dan whistle
- Menerapkan atau menghapus status apa pun
- Memaksa trigger kutukan
- Men-spawn atau menghapus musuh apa pun
- Menampilkan detection dan state musuh
- Menampilkan ID/hasil placer
- Menampilkan ID object persisten
- Memaksa autosave/load
- Membunuh pemain
- Menghapus run save tanpa menghapus pengetahuan
- Menghapus seluruh data save

### Data balance

Jaga nilai berikut agar dapat diedit tanpa perubahan kode:

- Harga dan stock toko
- Batas pengiriman/aturan penghitungan
- Damage, health, speed, detection, knockback, cooldown, dan ukuran kelompok musuh
- Durasi, charge, nilai lemparan, durability, dan nilai jual item
- Jarak kutukan, waktu diam, durasi, rentang, dan multiplier
- Peluang spawn loot dan musuh

### Uji penerimaan

- Tester dapat mencapai encounter apa pun dalam waktu kurang dari satu menit menggunakan debug tools.
- Build export tidak menampilkan debug UI secara default.
- Satu playthrough penuh dari New Game sampai Moon Whistle berhasil.
- Seed yang sama mereproduksi layout dan placer yang dilaporkan.

---

# 6. Menambahkan Konten Baru

Proses berikut sengaja dibuat singkat. Jika penambahan konten mengharuskan perubahan pada sistem yang tidak terkait, hentikan dan perbaiki fondasinya terlebih dahulu.

## 6.1 Menambahkan Item Baru

1. Duplikasi template Resource item.
2. Tetapkan ID stabil yang unik, nama, deskripsi, icon, sprite, stack size, harga, nilai jual, dan discovery threshold.
3. Pilih behavior yang sudah ada atau buat satu script/scene behavior kecil yang mengimplementasikan interface item.
4. Konfigurasikan aturan use, throw, impact, consumption, retrieval, dan persistent state.
5. Daftarkan Resource di `ContentCatalog`.
6. Tambahkan item ke satu atau beberapa pool loot/sumber.
7. Uji melalui debug grant, pickup, stacking, use, throw, sale, autosave, Continue, death, dan New Game.
8. Tambahkan hook art/audio tanpa mengubah kode inventory.

## 6.2 Menambahkan Musuh Baru

1. Duplikasi template scene musuh yang paling mirip.
2. Tetapkan `EnemyDefinition` dengan ID unik dan data tuning.
3. Gunakan kembali component bersama untuk health, hitbox, sight, sound, status, knockback, dan persistence.
4. Tulis hanya state machine kecil yang unik untuk musuh tersebut.
5. Implementasikan reaksi bersama yang relevan seperti sound, force, slow, obstruction, atau target override.
6. Tambahkan hook animation dan audio.
7. Tambahkan musuh ke pool placer; jangan pernah mengedit world generator hanya untuk menambahkan musuh.
8. Uji di arena, lalu di satu section asli.
9. Uji death, Continue, interaksi relic, dan pemulihan out-of-bounds.
10. Lakukan tuning melalui nilai Resource, bukan konstanta kode.

## 6.3 Menambahkan Variasi Section

1. Duplikasi template slot yang benar, bukan section lain yang tidak terkait.
2. Pertahankan origin, dimensi, seam anchor, dan bounds wajib.
3. Buat terrain statis dan collision.
4. Tempatkan marker enemy, loot, sumber, story, dan gate dengan ID unik.
5. Pastikan ada jalur turun dan naik.
6. Pastikan setidaknya ada satu rute yang tidak memerlukan loot acak yang mungkin tidak muncul.
7. Validasi seam dengan semua kemungkinan variasi section tetangga.
8. Jalankan validator section.
9. Uji dengan flyer, knockback, rope, dan behavior kutukan yang relevan.

---

# 7. Jadwal Empat Belas Hari

Jadwal ini berbasis milestone. Tugas di dalam satu milestone boleh diambil secara bebas.

## Hari 1 — Fondasi Project dan Export

- Tetapkan workflow repository, struktur folder, Input Map, resolusi, dan kepemilikan scene.
- Buat menu, gameplay shell, placeholder permukaan, dan placeholder pemain.
- Buat Autoload minimal dan template data.
- Hasilkan dan bagikan build export pertama.
- Lead menetapkan syarat gatekeeper terakhir atau memilih syarat placeholder yang paling sederhana.

**Syarat selesai:** Semua anggota dapat menjalankan project dan build export; `New Game` mencapai pemain placeholder yang dapat dikontrol.

## Hari 2 — Player, Kerangka Inventory, dan Kontrak Slot Dunia

- Movement, camera, health, damage, interaction, dan pause yang andal.
- Backpack lima slot, hotbar dua slot, kerangka pickup, use, dan throw.
- Template section, posisi slot tetap, dan kerangka pemilihan A/B.
- Template enemy placer dan loot placer.
- Draft schema meta/run save.

**Syarat selesai:** Pemain dapat mengambil dan melempar satu item sambil bergerak melewati dua section graybox yang tersambung.

## Hari 3 — Vertical Slice Pertama

- Multitool, batu yang dapat dipecahkan, Throwable Rock, rope, dan bandage.
- Satu musuh menggunakan sistem damage/knockback bersama.
- Prototype toko permukaan dan uang.
- Autosave dan `Continue` dasar.
- Tracker kutukan dengan profile placeholder.
- Lead menetapkan rentang tuning kutukan dan aturan gatekeeper Layer 2.

**Syarat selesai:** Build export mendukung `New Game`, membeli, turun, mengumpulkan/menggunakan item, naik, terkena kutukan, menjual, save, menu, dan `Continue` dalam satu slice kecil.

## Hari 4 — Fondasi Item dan Effect

- Behavior item lempar generik.
- Fondasi status: bleed, poison, slow, stun, mark, dan modifier.
- Sun Sphere, Rattlepod, Hushcap, dan Cling Resin.
- Overlay bahaya inventory dan deskripsi dikenal/tidak dikenal.
- Hasil placer deterministik dan ID collected persisten.

**Syarat selesai:** Empat relic bekerja terhadap musuh pertama di build terintegrasi dan mengikuti aturan save.

## Hari 5 — Graybox Layer 1 dan Musuh Inti

- Satu variasi graybox untuk setiap slot Layer 1.
- Amphibian, burung, thorn bloom, dan Lantern Snail.
- Driftseed dan pengambilan snail.
- Rope persisten sepanjang rute.
- Mulai mengganti art dan audio Layer 1.

**Syarat selesai:** Rute dari permukaan ke gerbang Layer 1 secara fisik dapat dilintasi melalui kedua sisi.

## Hari 6 — Loop Ancaman Layer 1

- Spider, poison, tracking mark, dan flyer besar.
- Pengujian obstruction dan keamanan gua.
- Interaksi gerbang senior diver.
- Jumlah pengiriman dan pemberian Blue Whistle.
- Behavior dan durability Silver Weight.

**Syarat selesai:** Pemain dapat menyelesaikan beberapa perjalanan permukaan, mendapatkan Blue Whistle, dan melewati gerbang Layer 1.

## Hari 7 — Hari Integrasi Layer 1

- Playtest penuh Layer 1 dengan ekonomi, kutukan, item, musuh, dan persistence.
- Perbaiki blocker sebelum menambah kompleksitas Layer 2.
- Implementasikan feedback dan shortcut debug yang masih kurang.
- Buat satu build milestone export yang bersih.

**Syarat selesai:** Layer 1 berfungsi sebagai game kecil yang lengkap tanpa blocker kritis.

## Hari 8 — Graybox dan Toko Layer 2

- Satu variasi graybox untuk setiap slot Layer 2.
- Pengujian movement di inverted canopy dan rope.
- Toko pertengahan yang aman dengan stock terbatas dan harga jual 75%.
- Curse profile Layer 2 dan batas health.
- Story bubble Layer 2/toko.

**Syarat selesai:** Pemain dapat bergerak dari gerbang Layer 1 ke placeholder gerbang terakhir Layer 2 dan kembali ke toko pertengahan.

## Hari 9 — Musuh Layer 2 dan Ending

- Monyet, variasi data burung kuat, kelompok flyer kecil, dan hippo.
- Syarat melewati gatekeeper terakhir.
- Pemberian Moon Whistle dan ending screen.
- Reaksi musuh/item diuji pada terrain terbalik.

**Syarat selesai:** Tersedia rute graybox lengkap dari `New Game` ke ending dengan menggunakan progres debug.

## Hari 10 — Penyelesaian Fitur

- Selesaikan seluruh behavior item P0, story bubble, UI, field persistence, dan penempatan konten yang tersisa.
- Validasi semua seam section.
- Validasi alur save/Continue serta death/pengetahuan baru secara penuh.
- Nonaktifkan atau tunda sistem P1 yang belum selesai.

**Syarat selesai:** Semua sistem P0 sudah tersedia; tidak ada arsitektur P0 baru yang dimulai setelah hari ini.

## Hari 11 — Feature Freeze dan Integrasi Konten

- Feature freeze.
- Integrasikan art, animation, audio, dan VFX final atau hampir final.
- Buat variasi section kedua hanya jika rute lengkap tetap stabil.
- Jalankan playtest pertama oleh non-developer.

**Syarat selesai:** Build export siap dipresentasikan meskipun beberapa variasi konten digunakan ulang.

## Hari 12 — Balance dan Pengujian Persistence

- Atur harga, peluang spawn, damage, knockback, penggunaan item, kutukan, dan jumlah pengiriman.
- Uji beberapa seed.
- Uji autosave saat berada di toko, encounter musuh, lemparan item, dan perpindahan layer.
- Uji run panjang, kematian, dan knowledge carryover ke `New Game`.

**Syarat selesai:** Tidak ada bug crash, persistence, atau progression kritis yang diketahui.

## Hari 13 — Release Candidate

- Selesaikan setidaknya tiga run penuh pada build export dengan seed berbeda.
- Uji pada komputer lain.
- Hanya perbaiki bug critical/high dan masalah presentasi yang cepat diselesaikan.
- Finalisasi controls, credits, level audio, dan ending.
- Siapkan rute presentasi dan backup save jika diizinkan aturan game jam.

**Syarat selesai:** Release candidate dapat langsung dikumpulkan.

## Hari 14 — Submission dan Demonstrasi

- Bekukan kode selain perbaikan yang menghalangi submission.
- Buat export final dan export cadangan.
- Verifikasi clean install, `New Game`, `Continue`, death, dan ending.
- Kemas file yang diperlukan dan lakukan submission lebih awal.
- Latih demonstrasi singkat untuk audiens.

**Syarat selesai:** Submission sudah diunggah dan berhasil diuji launch secara independen.

---

# 8. Panduan Dependency dan Pekerjaan Paralel

| Pekerjaan | Dapat segera dimulai | Bergantung pada | Hindari diedit bersamaan |
| --- | --- | --- | --- |
| Player movement | Ya | Input Map | Player root scene |
| Mockup menu/UI | Ya | Pilihan resolusi | Main UI scene |
| Data item | Ya | Konvensi ID | File content catalog |
| Test arena musuh | Ya | Interface damage | Shared enemy base |
| Graybox section | Setelah kontrak slot | Dimensi section | Scene section yang sama |
| Produksi art | Setelah kontrak scale/animation | Daftar scene placeholder | Scene collision milik programmer |
| Produksi audio | Ya, setelah daftar event | Penamaan event | Setup audio bus |
| SaveManager | Setelah schema state | ID stabil | Script autoload save |
| Toko | Setelah API inventory/uang | Definisi item | Scene UI toko |
| Kutukan | Setelah modifier pemain | Interface effect | Script stats pemain |
| Enemy placer | Setelah kontrak section/ID | Content catalog | Script generator |
| Story bubble | Setelah input/control lock | Dialogue Resource | Main dialogue scene |

Project lead harus menjaga daftar singkat **tugas siap kerja yang belum diambil** agar developer dapat berpindah pekerjaan tanpa menunggu penugasan baru.

---

# 9. Matriks Pengujian Wajib

## 9.1 Boot dan Flow

- Boot pertama tanpa save
- `New Game` tanpa pengetahuan
- `New Game` dengan relic yang sudah dikenal
- `Continue` setelah autosave tiga menit
- Kembali ke menu saat gameplay
- Keluar dari gameplay
- Forced close tidak lama setelah autosave
- Run save tidak valid/rusak

## 9.2 Persistence

- Placer yang sudah diambil tetap kosong
- Tumbuhan yang sudah dipanen tetap habis
- Musuh yang dikalahkan tetap mati
- Musuh hidup penting dipulihkan dengan aman
- Rope dipulihkan di posisi yang benar
- Silver Weight yang dijatuhkan dipulihkan dengan durability yang benar
- Stock toko dan uang dipulihkan
- Variasi section terpilih tidak di-roll ulang
- Trigger dialog dan gerbang tidak salah terulang
- Death menghapus run tetapi mempertahankan pengetahuan
- `New Game` me-reset dunia dan Red Whistle

## 9.3 Pemain dan Inventory

- Semua lima slot backpack dan dua hotbar terisi
- Stack mencapai delapan dan overflow ditolak atau ditempatkan dengan aman
- Inventory dibuka saat diserang musuh
- Use dan throw dengan posisi cursor dekat dan jauh
- Pickup saat inventory penuh
- Pencurian frog ketika terdapat item biasa
- Pencurian frog ketika hanya whistle tersedia
- Mengambil kembali whistle yang dicuri atau mendapatkan pengganti di permukaan
- Bandage saat bleed, poison, dan healing yang berkurang karena kutukan

## 9.4 Item

- Setiap item digunakan pada target valid dan tidak valid
- Setiap throwable membentur terrain, musuh, dan area dekat pemain
- Effect sementara dibersihkan
- Item retrievable tidak terduplikasi
- Lemparan pertama dan kedua Silver Weight
- Info Book membuka seluruh deskripsi
- Numbing Pill menyimpan sisa durasi
- Pengambilan, teriakan, dazzle, lure, pickup, dan penjualan Lantern Snail

## 9.5 Musuh

- Setiap musuh sendirian dan dalam kelompok yang direncanakan
- Reaksi terhadap noise, sight, slow, force, weight, dan obscuration
- Burung di dekat jurang mematikan
- Spider mark diikuti pengejaran flyer
- Obstruction dan kehilangan sight pada flyer
- Jarak kelompok monyet dan penanganan tepi platform
- Separation flyer kecil
- Telegraph, charge, benturan dinding, knockback, dan stun hippo
- Jalur berhasil dan ditolak untuk kedua gatekeeper

## 9.6 Ekonomi dan Progres

- Uang awal tepat 50g
- Penjualan harga penuh di permukaan
- Penjualan 75% yang dibulatkan di Layer 2
- Persistence stock terbatas Layer 2
- Batas pengiriman dengan stack
- Blue Whistle diberikan satu kali
- Penggantian whistle setelah hilang
- Moon Whistle dan ending diberikan satu kali

## 9.7 Dunia dan Kutukan

- Setiap kombinasi seam A/B yang dapat muncul
- Rute timur dan barat
- Turun dan naik melalui setiap section
- Kutukan tidak terpicu saat jump biasa atau bergerak turun
- Reset setelah diam sepuluh detik
- Modifier kutukan Layer 1
- Stack batas health Layer 2 sampai 50%
- Pill lima menit melewati transisi layer
- Rope tidak menciptakan shortcut keluar bounds

---

# 10. Urutan Pemangkasan Scope Jika Jadwal Terlambat

Pemangkasan harus tetap mempertahankan satu run yang dapat diselesaikan.

## Pangkas terlebih dahulu

1. VFX tambahan, portrait, teks typewriter, dan animasi UI dekoratif.
2. Variasi audio tingkat lanjut.
3. Solusi alternatif kreatif untuk gatekeeper terakhir; pertahankan satu syarat pasti untuk lewat.
4. Penyimpanan state AI musuh sementara secara presisi; pulihkan musuh yang masih hidup ke state placer yang aman.

## Pangkas berikutnya

5. Ganti variasi section kedua yang belum selesai dengan variasi yang sudah selesai atau perubahan tampilan ringan.
6. Kurangi ukuran kelompok monyet dan jumlah flyer kecil, bukan menghilangkan identitasnya.
7. Sederhanakan pertarungan senior diver sambil mempertahankan akses dengan Blue Whistle.
8. Sederhanakan reaksi khusus item-musuh menjadi hal bersama yang paling penting: sight, sound, slow, force, dan damage.

## Pangkas hanya sebagai langkah darurat

9. Gunakan langsung burung Layer 1 di Layer 2 tanpa visual baru.
10. Jadikan gatekeeper terakhir sebagai interaksi dialog/gerbang, bukan pertarungan.
11. Gunakan stock toko statis daripada stock acak, tetapi tetap pertahankan jumlah terbatas.

## Jangan pernah dipangkas

- Boot, `New Game`, `Continue`, pause, autosave, death, dan ending
- Satu rute lengkap melalui kedua layer
- Ekonomi permukaan dan progres Blue Whistle
- Gerbang senior diver dengan Blue Whistle
- Toko pertengahan Layer 2
- Gatekeeper terakhir dan ending Moon Whistle
- Loop inti inventory dan penggunaan/lemparan item
- Traversal menggunakan rope
- Paket kutukan kedua layer
- Musuh yang cukup untuk menyampaikan identitas setiap layer
- Export dan pengujian pada komputer bersih

---

# 11. Pemeriksaan Harian Tim

Pada awal setiap sesi:

- Apa milestone yang saat ini dapat dimainkan?
- Tugas P0 mana yang siap dan belum diambil?
- File bersama mana yang sedang diklaim?
- Apakah ada orang yang terblokir oleh interface atau asset yang belum tersedia?

Pada akhir setiap sesi:

- Apa yang menjadi dapat dimainkan di build utama hari ini?
- Apa yang rusak?
- Apa yang belum terintegrasi?
- Apakah build export masih dapat dibuka?
- Apakah milestone terbaru masih dapat diselesaikan?
- Bug critical/high apa yang masih terbuka?
- Apa satu prioritas integrasi untuk besok?

Project lead harus memainkan build terintegrasi setiap hari, menjaga scope, segera menetapkan nilai yang belum diputuskan, dan mencegah polish opsional menyembunyikan progres yang rusak.

---

# 12. Standar Penyelesaian Final

Build game jam dianggap selesai ketika:

- Game hasil export dapat boot ke menu yang dapat digunakan.
- `New Game` membuat dunia berbasis seed dengan Red Whistle, multitool, dan 50g.
- `Continue` memulihkan run hidup setelah autosave.
- Pengetahuan bertahan setelah death dan `New Game`, sementara semua hal lain di-reset.
- Kedua layer tersusun dari section authored yang tersambung tanpa transisi.
- Enemy placer dan loot placer deterministik berperilaku konsisten.
- Pemain dapat menggunakan, melempar, membawa, men-stack, menjual, dan mempelajari seluruh daftar item.
- Layer 1 mendukung progres kembali ke permukaan dan perolehan Blue Whistle.
- Senior diver mengizinkan pemegang Blue Whistle lewat.
- Layer 2 memiliki toko pertengahan dan identitas musuh yang direncanakan.
- Kedua kutukan saat naik bekerja dan menyampaikan konsekuensinya.
- Gatekeeper terakhir dapat dilewati secara andal.
- Moon Whistle dan ending diberikan tepat satu kali.
- Tidak ada bug kritis yang menghalangi satu playthrough lengkap pada build export.
- Submission diuji pada komputer selain komputer development utama.
