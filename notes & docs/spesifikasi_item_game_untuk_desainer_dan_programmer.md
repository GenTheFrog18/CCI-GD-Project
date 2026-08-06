# Spesifikasi Item Game untuk Desainer dan Programmer

## Tujuan Dokumen

Dokumen ini menjelaskan semua item yang direncanakan untuk build game jam. Setiap spesifikasi memisahkan kebutuhan pemain, kebutuhan desain/art, dan kebutuhan programming agar anggota tim dapat mengerjakan item tanpa menebak aturan dasarnya.

Nama item berbahasa Inggris dipertahankan sebagai nama dalam game. Identifier teknis adalah saran dan harus dikunci sebelum implementasi konten dimulai.

Nilai yang diberi label **nilai awal playtest** bukan keputusan final. Nilai tersebut cukup konkret untuk membuat prototype, lalu dapat diubah melalui Resource/Inspector tanpa mengubah kode.

---

# 1. Aturan Bersama Semua Item

## 1.1 Inventory dan Kontrol

- Pemain memiliki lima slot backpack dan dua slot hotbar.
- Item biasa dapat di-stack sampai delapan unit jika tidak memiliki state instance unik.
- Whistle berada di slot khusus dan tidak memakai slot backpack/hotbar.
- Klik kiri menggunakan item hotbar aktif.
- Klik kanan melempar item hotbar aktif ke arah cursor.
- Kekuatan lemparan ditentukan oleh jarak cursor dari pemain dan dibatasi nilai minimum/maksimum.
- Item yang tidak memiliki efek lempar khusus dapat dilempar sebagai object biasa dan diambil kembali, kecuali dinyatakan lain.
- Membuka inventory memperlambat pemain, menutupi tengah layar, dan menggelapkan bagian lain.
- Item yang berada di dunia harus memiliki collision, sprite, prompt pickup, dan persistent ID jika perlu bertahan setelah autosave.

## 1.2 Status Pengetahuan

- Item supply biasa dan equipment awal dapat langsung memiliki deskripsi lengkap.
- Relic yang belum dikenal menampilkan deskripsi samar berdasarkan petunjuk visual.
- Relic yang sudah dikenal menampilkan fungsi dan risikonya secara langsung.
- Setiap relic melacak jumlah penggunaan selama run saat ini.
- Jika penggunaan mencapai batas item tersebut lalu pemain mati, deskripsi lengkap dibuka secara permanen.
- Progres penggunaan parsial tidak dibawa ke run berikutnya.
- `Info Book` membuka semua deskripsi secara langsung.

## 1.3 Harga

Toko permukaan membeli relic pada 100% nilai dasar. Toko Layer 2 membeli pada `round(nilai_dasar × 0,75)`.

| Relic | Permukaan | Layer 2 |
| --- | ---: | ---: |
| Sun Sphere | 20g | 15g |
| Lantern Snail | 50g | 38g |
| Rattlepod | 30g | 23g |
| Hushcap | 30g | 23g |
| Cling Resin | 50g | 38g |
| Driftseed | 30g | 23g |
| Silver Weight | 150g | 113g |

Item supply, Multitool, whistle, dan Throwable Rock tidak perlu dapat dijual kembali dalam build jam.

## 1.4 Kontrak Data Minimum

Setiap `ItemDefinition` setidaknya menyimpan:

- `item_id`
- `display_name`
- `category`
- `unknown_description`
- `known_description`
- `icon`
- `world_sprite`
- `max_stack`
- `purchase_price`
- `surface_sale_value`
- `discovery_use_threshold`
- `behavior`
- Aturan konsumsi, retrieval, dan persistence
- Hook audio dan VFX

Behavior khusus item tidak boleh mengubah inventory secara langsung. Behavior harus mengembalikan hasil penggunaan kepada sistem inventory, misalnya jumlah yang dikonsumsi, world object yang dibuat, atau state instance yang berubah.

---

# 2. Ringkasan Seluruh Item

| ID Saran | Item | Kategori | Fungsi Utama | Stack |
| --- | --- | --- | --- | ---: |
| `rope` | Rope | Traversal supply | Membuat jalur panjat sepanjang ±5 meter | 8 |
| `whistle_red` | Red Whistle | Progression credential | Kredensial awal Layer 1 | 1, slot khusus |
| `whistle_blue` | Blue Whistle | Progression credential | Melewati senior diver menuju Layer 2 | 1, slot khusus |
| `whistle_moon` | Moon Whistle | Ending reward | Menandai tamatnya build game jam | 1, slot khusus |
| `multitool` | Multitool | Starting tool | Interaksi, memecahkan batu, mengambil snail, serangan lemah | 1 |
| `bandage` | Bandage | Medical supply | Menghentikan bleed dan memulihkan 50 health perlahan | 8 |
| `info_book` | Info Book | Knowledge supply | Membuka semua deskripsi item | 1 disarankan |
| `numbing_pill` | Numbing Pill | Curse supply | Menekan kutukan saat naik selama ±5 menit | 8 |
| `sun_sphere` | Sun Sphere | Light relic | Cahaya sementara yang dapat dilempar | 8 |
| `throwable_rock` | Throwable Rock | Basic weapon/tool | Damage dan knockback lempar sederhana | 8 |
| `lantern_snail` | Lantern Snail | Living light/lure relic | Cahaya, dazzle, teriakan, dan pengalih musuh | 8 saat tenang |
| `rattlepod` | Rattlepod | Sound relic | Membuat sumber suara lokal atau jarak jauh | 8 |
| `hushcap` | Hushcap | Concealment relic | Membuat cloud yang menghalangi pandangan | 8 |
| `cling_resin` | Cling Resin | Area-control relic | Membuat area lengket yang memperlambat | 8 |
| `driftseed` | Driftseed | Gravity relic | Mengurangi gravitasi tetapi memperbesar knockback | 8 |
| `silver_weight` | Silver Weight | Rare weapon/weight relic | Menambah berat dan membunuh monster kecil saat dilempar | 1 per instance |

---

# 3. Spesifikasi Per Item

## 3.1 Rope

**ID saran:** `rope`  
**Kategori:** Traversal supply  
**Harga beli:** 20g di toko permukaan  
**Nilai jual:** Tidak dijual sebagai relic  
**Stack:** Maksimum 8  
**Sumber:** Toko permukaan; stock Layer 2 bila dikonfigurasi

### Deskripsi untuk pemain

> Tali sepanjang kira-kira lima meter. Dapat dipasang pada permukaan yang sesuai untuk membuat jalur naik atau turun yang aman. Tali yang sudah dipasang tidak dapat diambil kembali.

### Kegunaan dan kontrol

- **Klik kiri:** Masuk ke mode pemasangan atau langsung memasang pada anchor valid di dekat cursor.
- Pemasangan mengonsumsi satu Rope.
- Rope terbentang vertikal sekitar lima meter atau sampai menyentuh terrain lebih dahulu.
- Rope dapat digunakan untuk turun dengan aman dan menyiapkan rute pulang.
- **Klik kanan—usulan:** Melempar gulungan sebagai object biasa tanpa memasangnya; gulungan dapat diambil kembali.

### Aturan desain

- Rope adalah investasi permanen selama run, bukan alat yang bisa dipindahkan berulang kali.
- Harus selalu ada rute alami yang lebih berbahaya agar pemain tidak terblokir ketika tidak memiliki Rope.
- Jangan mengharuskan terlalu banyak Rope untuk menyelesaikan rute utama karena satu Rope hanya mencakup lima meter.

### Kebutuhan art/audio

- Icon gulungan yang jelas.
- World sprite gulungan.
- Visual rope lurus/tileable.
- Anchor atau simpul bagian atas.
- Suara pemasangan dan suara memanjat ringan.

### Kebutuhan programming

- Validasi anchor, ruang vertikal, dan panjang maksimum.
- Rope terpasang memiliki persistent ID, posisi, panjang, dan section parent.
- Rope disimpan saat autosave dan dihapus saat run berakhir.
- Rope terpasang tidak dapat di-pickup.
- Pemain tidak boleh terjebak di dalam collision saat rope dibuat.

---

## 3.2 Red Whistle

**ID saran:** `whistle_red`  
**Kategori:** Progression credential  
**Harga/nilai jual:** Tidak dapat dibeli atau dijual  
**Stack:** Satu, slot whistle khusus  
**Sumber:** Diberikan saat `New Game`; dapat diganti di permukaan jika hilang

### Deskripsi untuk pemain

> Whistle untuk diver pemula. Menunjukkan bahwa pemiliknya hanya diizinkan beroperasi di Layer 1.

### Kegunaan

- Menjadi kredensial awal pemain.
- Tidak memiliki aksi aktif selama build jam.
- Tidak dapat dilempar secara normal.
- Digantikan oleh Blue Whistle setelah batas pengiriman relic tercapai.
- Frog hanya boleh mencurinya jika pemain tidak memiliki item inventory biasa yang dapat dicuri.

### Kebutuhan art/audio

- Icon/sprite merah yang mudah dibedakan dari whistle lain.
- Bentuk dasar yang sama dengan upgrade whistle agar progres visual terbaca.
- Tidak memerlukan animasi penggunaan.

### Kebutuhan programming

- Disimpan di slot whistle khusus.
- Senior diver membaca `whistle_id`, bukan mencari item dalam backpack.
- Jika dicuri, whistle berubah menjadi world item yang dibawa frog.
- Toko/layanan permukaan dapat memberikan pengganti jika pemain kembali tanpa whistle.

---

## 3.3 Blue Whistle

**ID saran:** `whistle_blue`  
**Kategori:** Progression credential  
**Harga/nilai jual:** Tidak dapat dibeli atau dijual  
**Stack:** Satu, slot whistle khusus  
**Sumber:** Hadiah setelah batas pengiriman, nilai awal 10 unit relic

### Deskripsi untuk pemain

> Whistle untuk diver yang telah membuktikan kemampuannya. Senior diver di dasar Layer 1 akan mengizinkan pemiliknya memasuki Layer 2.

### Kegunaan

- Menggantikan Red Whistle.
- Membuka jalur normal melewati senior diver.
- Tidak memiliki aksi aktif dan tidak dapat dilempar normal.
- Tetap dapat dicuri frog hanya jika tidak ada item inventory biasa.

### Kebutuhan art/audio

- Icon/sprite biru yang jelas.
- Efek pemberian singkat dan cue audio progres.
- Story bubble saat pertama diterima.

### Kebutuhan programming

- Event pemberian hanya boleh terjadi satu kali.
- Nilai batas pengiriman dan cara menghitung stack harus data-driven.
- Mengganti whistle saat ini tanpa menyentuh slot backpack.
- State tersimpan dalam run save, tetapi di-reset menjadi Red Whistle pada `New Game`.

---

## 3.4 Moon Whistle

**ID saran:** `whistle_moon`  
**Kategori:** Ending reward  
**Harga/nilai jual:** Tidak dapat dibeli atau dijual  
**Stack:** Satu, slot whistle khusus  
**Sumber:** Gatekeeper terakhir di dasar Layer 2

### Deskripsi untuk pemain

> Whistle langka yang diberikan kepada diver yang berhasil mencapai batas terdalam perjalanan ini.

### Kegunaan

- Menggantikan Blue Whistle.
- Menandai penyelesaian build game jam.
- Memicu urutan dialog ending dan ending screen.
- Layer 3 tidak perlu dapat dimainkan.

### Kebutuhan art/audio

- Siluet paling istimewa di antara tiga whistle.
- Warna atau motif bulan yang jelas.
- Efek pemberian, suara khusus, dan tampilan ending.

### Kebutuhan programming

- Hanya dapat diberikan satu kali.
- Pemberian harus menyimpan state sebelum ending screen.
- Ending tetap dapat dipulihkan secara aman jika game ditutup setelah pemberian.

---

## 3.5 Multitool

**ID saran:** `multitool`  
**Kategori:** Starting tool  
**Harga/nilai jual:** Tidak dapat dibeli atau dijual  
**Stack:** Satu  
**Sumber:** Equipment awal setiap run

### Deskripsi untuk pemain

> Alat sederhana untuk memecahkan batu rapuh, mengambil makhluk tertentu, dan melakukan interaksi jarak dekat. Dapat digunakan sebagai pertahanan terakhir, tetapi damage-nya sangat kecil.

### Kegunaan dan kontrol

- **Klik kiri:** Interaksi/ayunan pendek menuju cursor.
- Memecahkan batu yang menyembunyikan relic.
- Mengambil Lantern Snail melalui interaksi yang sesuai.
- Memukul musuh dalam jarak sangat pendek dengan damage rendah.
- Dapat memaksa frog menjatuhkan item curian jika aturan tersebut dipilih.
- Tidak dapat dilempar, dijual, dijatuhkan, atau dicuri.

### Aturan desain

- Multitool bukan senjata utama.
- Jarak dan damage harus cukup rendah agar artifact tetap menjadi pusat permainan.
- Feedback memecahkan batu harus jelas dan memuaskan karena merupakan interaksi berulang.

### Kebutuhan art/audio

- Sprite kecil yang terbaca saat dipegang.
- Animasi ayunan/interaksi singkat.
- Efek benturan berbeda untuk batu, makhluk, dan terrain biasa.
- Suara metal/alat yang ringan.

### Kebutuhan programming

- Gunakan area/raycast pendek dan interface interaksi bersama.
- Prioritas target: interactable khusus, breakable rock, lalu damage target.
- Pastikan satu ayunan tidak mengenai target yang sama beberapa kali.
- **Keputusan yang belum dikunci:** Apakah Multitool memakai satu hotbar slot atau memiliki tool slot/input terpisah. Untuk menjaga dua slot artifact tetap berguna, tool slot terpisah lebih disarankan.

---

## 3.6 Bandage

**ID saran:** `bandage`  
**Kategori:** Medical supply  
**Harga beli:** 50g  
**Nilai jual:** Tidak perlu dijual kembali  
**Stack:** Maksimum 8  
**Sumber:** Toko permukaan; stock terbatas Layer 2 bila ditentukan

### Deskripsi untuk pemain

> Perban bersih yang langsung menghentikan bleeding dan perlahan memulihkan hingga 50 health. Kutukan dapat mengurangi jumlah healing yang diterima.

### Kegunaan dan kontrol

- **Klik kiri:** Mengonsumsi satu Bandage.
- Menghapus status bleed segera saat penggunaan berhasil.
- Memulai healing perlahan dengan total dasar 50 health.
- Healing mematuhi multiplier Layer 1 dan batas health Layer 2.
- **Klik kanan:** Melempar paket tanpa mengaktifkannya; dapat diambil kembali.

### Nilai awal playtest

- Total healing: 50.
- Durasi healing: 4–6 detik.
- Damage tidak membatalkan healing pada prototype awal kecuali playtest menunjukkan healing terlalu aman.

### Kebutuhan art/audio

- Icon perban bersih dan world sprite paket kecil.
- Feedback lilitan/perawatan singkat.
- Partikel atau tick UI healing yang lembut.
- Suara kain dan cue selesai.

### Kebutuhan programming

- Semua healing melewati satu API agar modifier kutukan selalu dihormati.
- Item tidak boleh dikonsumsi jika health penuh dan tidak ada bleed, kecuali pemain diberi konfirmasi.
- Save/Continue menyimpan sisa healing-over-time jika masih aktif.

---

## 3.7 Info Book

**ID saran:** `info_book`  
**Kategori:** Knowledge supply  
**Harga beli:** 30g  
**Nilai jual:** Tidak perlu dijual kembali  
**Stack:** Maksimum 1 disarankan  
**Sumber:** Toko permukaan

### Deskripsi untuk pemain

> Buku panduan relic untuk diver baru. Menggunakan buku ini langsung membuka deskripsi lengkap seluruh item untuk run sekarang dan run berikutnya.

### Kegunaan dan kontrol

- **Klik kiri:** Mengonsumsi buku dan menandai semua deskripsi item sebagai dikenal.
- Pengetahuan disimpan ke meta save saat itu juga.
- Jika seluruh item sudah dikenal, toko sebaiknya menandai buku sebagai tidak diperlukan atau mencegah pembelian.
- **Klik kanan:** Melempar buku sebagai object biasa; dapat diambil kembali.

### Aturan desain

- Item ini merupakan bantuan presentasi agar audiens besar dapat memahami item dalam sesi singkat.
- Harganya cukup rendah agar pemain baru dapat memilih satu Rope dan satu Info Book dengan 50g awal.

### Kebutuhan art/audio

- Icon buku panduan dengan simbol relic.
- World sprite buku kecil.
- Efek UI yang menampilkan bahwa seluruh entry telah dibuka.

### Kebutuhan programming

- Memperbarui meta save, bukan hanya state run.
- Mengirim signal agar semua panel deskripsi yang terbuka melakukan refresh.
- Event harus idempotent: penggunaan kedua tidak menyebabkan error atau duplikasi.

---

## 3.8 Numbing Pill

**ID saran:** `numbing_pill`  
**Kategori:** Curse-management supply  
**Harga beli:** 120g  
**Nilai jual:** Tidak perlu dijual kembali  
**Stack:** Maksimum 8  
**Sumber:** Toko permukaan dan stock terbatas Layer 2

### Deskripsi untuk pemain

> Obat mahal yang menekan gejala kutukan saat naik selama kira-kira lima menit. Cukup untuk melintasi sekitar setengah layer jika pemain terus bergerak.

### Kegunaan dan kontrol

- **Klik kiri:** Mengonsumsi satu pill dan memulai durasi suppression 300 detik.
- Selama aktif, trigger jarak saat naik tidak menerapkan paket kutukan baru.
- Durasi ditampilkan di HUD.
- **Klik kanan:** Melempar pill sebagai object biasa; dapat diambil kembali.

### Aturan desain

- Pill membeli kecepatan dan keamanan saat naik, tetapi pemain tetap dapat bergerak perlahan dan berhenti setiap screen height sebagai alternatif.
- **Aturan awal yang disarankan:** Pill tidak menghapus stack batas health Layer 2 yang sudah terjadi; hanya mencegah penerapan baru.
- Menggunakan pill kedua dapat me-refresh atau menambah durasi. Pilih satu aturan dan tampilkan dengan jelas.

### Kebutuhan art/audio

- Bentuk obat yang mudah dibedakan dari relic organik.
- Icon status dengan countdown.
- Perubahan audio/visual singkat saat suppression dimulai dan berakhir.

### Kebutuhan programming

- Simpan sisa durasi saat autosave.
- Timer hanya berjalan selama gameplay aktif, bukan saat pause.
- Curse tracker tetap memperbarui referensi kedalaman dengan konsisten selama suppression.

---

## 3.9 Sun Sphere

**ID saran:** `sun_sphere`  
**Kategori:** Light relic  
**Nilai jual:** 20g permukaan, 15g Layer 2  
**Stack:** Maksimum 8  
**Sumber:** Relic sangat umum di Layer 1

### Deskripsi belum dikenal

> Bola hangat dan rapuh. Cahaya kecil bergerak di dalamnya seolah mencari jalan keluar.

### Deskripsi sudah dikenal

> Pecahkan atau lempar untuk menghasilkan cahaya sementara. Cahaya cepat padam, tetapi cukup untuk memeriksa lorong gelap tanpa membawa makhluk hidup.

### Kegunaan dan kontrol

- **Klik kiri:** Mengaktifkan sphere di tangan atau menjatuhkannya aktif di dekat pemain.
- **Klik kanan:** Melempar; sphere otomatis aktif saat dilempar atau saat impact.
- Menghasilkan cahaya lokal tanpa damage berarti.
- Setelah durasi habis, sphere menjadi inert lalu menghilang.

### Nilai awal playtest

- Durasi cahaya: 20–30 detik.
- Radius cukup untuk melihat ancaman satu layar kecil, bukan menerangi seluruh cave.
- Discovery threshold: satu penggunaan.

### Kebutuhan art/audio

- State tidak aktif, aktif, hampir padam, dan padam.
- Cahaya hangat yang berbeda dari Lantern Snail.
- Suara pecah/aktivasi ringan dan ambience redup.

### Kebutuhan programming

- World light mengikuti sphere yang dilempar.
- Timer, posisi, dan state aktif perlu disimpan hanya jika sphere dianggap world object persisten; alternatif aman adalah membersihkan sphere sementara saat load.
- Sphere tidak boleh memicu efek cahaya berulang pada setiap collision.

---

## 3.10 Throwable Rock

**ID saran:** `throwable_rock`  
**Kategori:** Basic weapon/tool  
**Nilai jual:** Tidak dapat dijual  
**Stack:** Maksimum 8  
**Sumber:** Dihasilkan saat pemain memecahkan batu yang menyembunyikan relic

### Deskripsi untuk pemain

> Batu biasa. Tidak berharga, tetapi cukup berat untuk mengganggu makhluk kecil, memicu hazard dari jarak aman, atau memberikan damage sederhana saat dilempar.

### Kegunaan dan kontrol

- **Klik kiri:** Tidak memiliki efek artifact khusus; dapat digunakan untuk inspeksi/aim jika diperlukan UI.
- **Klik kanan:** Melempar sesuai arah dan kekuatan cursor.
- Memberikan damage langsung sederhana dan knockback berdasarkan kecepatan impact.
- Dapat mengagitasi Thorn Bloom atau object lain yang bereaksi pada benturan.
- Dapat diambil kembali jika berhenti di lokasi yang dapat dijangkau.

### Aturan desain

- Merupakan pengecualian dasar untuk direct-damage artifact.
- Damage harus berguna untuk mengganggu, tetapi tidak menjadikan spam batu sebagai solusi terbaik semua musuh.

### Kebutuhan art/audio

- Beberapa variasi sprite batu opsional.
- Putaran sederhana saat terbang.
- Suara impact berbeda untuk tanah, tumbuhan, dan makhluk.

### Kebutuhan programming

- Damage dihitung dari velocity dengan batas maksimum.
- Gunakan thrown-item foundation yang sama dengan relic lain.
- Rock yang diam berubah menjadi pickup dan perlu persistent ID jika bertahan setelah autosave.

---

## 3.11 Lantern Snail

**ID saran:** `lantern_snail`  
**Kategori:** Living light/lure relic  
**Nilai jual:** 50g permukaan, 38g Layer 2  
**Stack:** Maksimum 8 ketika tenang; instance aktif harus terpisah  
**Sumber:** Lantern Snail di dekat gua Layer 1 dan di Layer 2; diambil dengan Multitool

### Deskripsi belum dikenal

> Makhluk kecil dengan cahaya terang di cangkangnya. Tubuhnya bergetar ketika disentuh.

### Deskripsi sudah dikenal

> Memberikan cahaya selama dibawa. Jika diganggu atau terkena benturan keras, snail menjerit, menyilaukan penggunanya, dan menarik perhatian makhluk terbang besar ke lokasi suara.

### Kegunaan dan kontrol

- Memberikan cahaya pasif selama berada di hotbar atau aktif sesuai keputusan UI.
- **Klik kiri:** Mengagitasi/squeeze snail dan memicu teriakan setelah wind-up singkat.
- **Klik kanan:** Melempar snail; impact di atas batas tertentu membuatnya menjerit.
- Teriakan mengirim sound event berprioritas tinggi.
- Dazzle mengganggu pandangan pemain di sekitar lokasi.
- Snail dapat diambil kembali setelah tenang.

### Nilai awal playtest

- Cooldown teriakan: 6–10 detik.
- Discovery threshold: dua agitasi/teriakan.
- Teriakan mengalihkan target flyer besar kecuali tracking mark spider memiliki prioritas desain lebih tinggi.

### Kebutuhan art/audio

- State tenang, takut/agitated, menjerit, dan cooldown.
- Cahaya dari cangkang.
- Animasi tubuh bergetar sebelum teriakan.
- Teriakan yang sangat khas dan cue dazzle visual yang tidak menyakitkan mata.

### Kebutuhan programming

- Makhluk dunia dan item inventory berbagi `item_id`, tetapi menggunakan scene berbeda.
- Harvest mengubah creature menjadi item tanpa death/drop.
- Sound event harus dapat didengar AI melalui interface bersama.
- Simpan state instance jika snail sedang berada di dunia, termasuk posisi dan cooldown bila diperlukan.

---

## 3.12 Rattlepod

**ID saran:** `rattlepod`  
**Kategori:** Sound/distraction relic  
**Nilai jual:** 30g permukaan, 23g Layer 2  
**Stack:** Maksimum 8  
**Sumber:** Tumbuh di dekat cliffsides

### Deskripsi belum dikenal

> Polong kering berisi biji keras. Sedikit gerakan membuatnya berderak keras.

### Deskripsi sudah dikenal

> Menghasilkan beberapa pulsa suara. Dapat dibunyikan di tangan untuk menarik perhatian ke pemain atau dilempar untuk membuat sumber suara di lokasi lain.

### Kegunaan dan kontrol

- **Klik kiri:** Mengguncang pod dan membuat pulsa suara di posisi pemain.
- **Klik kanan:** Melempar pod; pod mulai berderak setelah impact.
- Semua makhluk yang mendengar dapat menyelidiki, menjadi agitated, atau bereaksi sesuai profile mereka.
- Rattlepod tidak memberikan damage berarti.

### Nilai awal playtest

- Tiga pulsa suara sebelum kosong.
- Jeda antar-pulsa: 0,6–1 detik.
- Pod kosong tidak dapat dijual dan dapat menghilang.
- Discovery threshold: dua pulsa atau satu lemparan aktif.

### Kebutuhan art/audio

- State penuh dan kosong.
- Gerakan biji/animasi shake yang terlihat.
- Suara rattle tajam dengan jangkauan yang mudah dikenali pemain.

### Kebutuhan programming

- Gunakan satu `SoundEvent` bersama berisi posisi, radius, jenis suara, dan prioritas.
- AI menentukan reaksinya sendiri; Rattlepod tidak memanggil script musuh tertentu.
- Jumlah pulsa tersisa pada instance aktif harus tersimpan jika item dapat diambil kembali.

---

## 3.13 Hushcap

**ID saran:** `hushcap`  
**Kategori:** Concealment relic  
**Nilai jual:** 30g permukaan, 23g Layer 2  
**Stack:** Maksimum 8  
**Sumber:** Tumbuh di dekat pintu masuk gua

### Deskripsi belum dikenal

> Jamur gelap dengan spore tebal. Cahaya tampak redup ketika melewati permukaannya.

### Deskripsi sudah dikenal

> Menghasilkan cloud gelap yang menghalangi pandangan pemain dan makhluk. Suara tetap dapat melewati cloud tersebut.

### Kegunaan dan kontrol

- **Klik kiri:** Menghancurkan Hushcap dan membuat cloud di sekitar pemain.
- **Klik kanan:** Melempar Hushcap dan membuat cloud di titik impact.
- Makhluk berbasis sight kehilangan atau kesulitan mempertahankan target melalui cloud.
- Cloud juga menghalangi pandangan pemain.
- Tidak meredam suara dan tidak memberikan damage.

### Nilai awal playtest

- Durasi cloud: 5–7 detik.
- Radius: cukup untuk menutup satu area kecil/chokepoint.
- Satu kali penggunaan dan langsung dikonsumsi.
- Discovery threshold: satu penggunaan.

### Kebutuhan art/audio

- Siluet jamur gelap yang jelas di cave entrance.
- Cloud dengan batas lembut, tetapi area mekanis tetap dapat dipahami.
- Suara pecah dan semburan spore.

### Kebutuhan programming

- Gunakan Area2D untuk modifier visibility/targeting.
- Sight detector AI harus memeriksa obscuration bersama, bukan daftar Hushcap khusus.
- Efek visual player dan efek AI memakai sumber durasi yang sama.
- Cloud bersifat sementara dan dapat dibersihkan saat load.

---

## 3.14 Cling Resin

**ID saran:** `cling_resin`  
**Kategori:** Area-control relic  
**Nilai jual:** 50g permukaan, 38g Layer 2  
**Stack:** Maksimum 8  
**Sumber:** Diambil dari pohon Layer 1 dan Layer 2

### Deskripsi belum dikenal

> Resin sangat lengket yang terus menempel pada wadahnya. Debu dan daun hampir tidak dapat terlepas setelah menyentuhnya.

### Deskripsi sudah dikenal

> Membuat area lengket yang memperlambat pemain, makhluk, dan object fisik ringan. Efeknya tidak membedakan kawan atau lawan.

### Kegunaan dan kontrol

- **Klik kiri:** Menuangkan patch kecil di dekat atau di bawah pemain.
- **Klik kanan:** Melempar wadah; pecah dan membuat patch lebih besar di titik impact.
- Body yang masuk menerima slow.
- Projectile fisik dapat diperlambat atau kehilangan jangkauan.
- Resin tidak memberikan damage langsung.

### Nilai awal playtest

- Durasi area: 12–18 detik.
- Slow karakter: 40–60%.
- Pemain terkena efek yang sama.
- Wadah dikonsumsi saat digunakan.
- Discovery threshold: satu penggunaan.

### Kebutuhan art/audio

- Wadah resin dan sprite resin pada pohon.
- Patch lantai yang jelas tanpa terlihat seperti terrain solid.
- Stretch/splash saat impact.
- Suara lengket yang khas.

### Kebutuhan programming

- Area2D memberikan modifier slow melalui interface bersama.
- Track body masuk/keluar agar modifier selalu dilepas dengan benar.
- Projectile menggunakan multiplier velocity terpisah jika mendukung slow.
- Patch sementara dapat dibersihkan saat load.

---

## 3.15 Driftseed

**ID saran:** `driftseed`  
**Kategori:** Gravity/mobility relic  
**Nilai jual:** 30g permukaan, 23g Layer 2  
**Stack:** Maksimum 8  
**Sumber:** Diambil dari pohon Layer 1 dan Layer 2

### Deskripsi belum dikenal

> Biji besar yang terus menarik tangkainya ke atas. Debu di sekitarnya jatuh jauh lebih lambat.

### Deskripsi sudah dikenal

> Menempel pada target dan mengurangi gravitasi untuk sementara, tetapi membuat target jauh lebih mudah terdorong oleh knockback.

### Kegunaan dan kontrol

- **Klik kiri:** Menempelkan Driftseed pada pemain.
- **Klik kanan:** Melempar; menempel pada makhluk kecil atau object bergerak pertama yang terkena.
- Mengurangi kecepatan jatuh dan mengubah lintasan movement.
- Meningkatkan multiplier knockback selama aktif.
- Sangat berguna untuk inverted canopy Layer 2, tetapi berbahaya saat menghadapi burung, monyet, atau flyer.

### Nilai awal playtest

- Durasi: 10–15 detik.
- Gravity multiplier: 0,35–0,5.
- Knockback received multiplier: 1,5–1,8.
- Satu kali penggunaan; seed habis setelah efek berakhir.
- Discovery threshold: dua penggunaan atau satu penggunaan penuh.

### Kebutuhan art/audio

- Seed dengan bulu/serat yang jelas menunjukkan gaya ke atas.
- Tali atau attachment visual pada target.
- Partikel ringan bergerak ke atas.
- Cue suara saat menempel dan lepas.

### Kebutuhan programming

- Terapkan modifier gravitasi dan knockback melalui status system.
- Jangan mengubah constant player secara langsung; gunakan modifier yang dapat dilepas.
- Tentukan whitelist target valid agar tidak menempel pada gatekeeper/big enemy secara tidak sengaja.
- Simpan sisa durasi bila effect aktif saat autosave.

---

## 3.16 Silver Weight

**ID saran:** `silver_weight`  
**Kategori:** Rare weapon/weight relic  
**Nilai jual:** 150g permukaan, 113g Layer 2  
**Stack:** Tidak di-stack; setiap instance menyimpan durability  
**Sumber:** Sangat langka di Layer 1 atau Layer 2, maksimum satu per run

### Deskripsi belum dikenal

> Batu perak yang terlalu berat untuk ukurannya. Retakan halus terlihat di bagian dalamnya ketika terkena benturan.

### Deskripsi sudah dikenal

> Membuat pemegangnya berat dan sulit terdorong. Ketika dilempar, langsung membunuh monster kecil. Weight pecah setelah lemparan kedua.

### Kegunaan dan kontrol

- **Tahan klik kiri:** Membuat pemain lebih berat selama item aktif.
- Saat berat, pemain bergerak lebih lambat, sulit melompat, dan menerima knockback lebih kecil.
- **Klik kanan:** Melempar Silver Weight.
- Impact membunuh musuh dengan tag `small_enemy`.
- Musuh besar tidak langsung mati; menerima impact/knockback berdasarkan tuning.
- Lemparan pertama membuat retak dan masih dapat diambil kembali.
- Lemparan kedua menghancurkan Silver Weight setelah impact.

### Nilai awal playtest

- Durability awal: 2.
- Movement multiplier saat berat: 0,55–0,7.
- Knockback received multiplier: 0,25–0,5.
- Jump sangat berkurang atau dinonaktifkan selama menahan efek.
- Discovery threshold: satu lemparan atau satu penggunaan efek berat.

### Aturan ekonomi yang perlu dikunci

Jika Silver Weight yang sudah digunakan sekali tetap bernilai 150g, strategi optimal adalah mendapatkan satu instant kill gratis lalu menjualnya dengan harga penuh. Pilihan yang disarankan:

- Durability 2: 150g
- Durability 1: 75–100g
- Durability 0: pecah, 0g

Jika harga tetap penuh setelah lemparan pertama, retrieval harus cukup berisiko agar keputusan tersebut tidak otomatis.

### Kebutuhan art/audio

- State utuh dan retak yang sangat mudah dibedakan.
- Sprite berat dengan putaran lambat saat dilempar.
- Impact berat, screen shake kecil, dan suara logam/batu yang kuat.
- Efek pecah khusus pada lemparan kedua.

### Kebutuhan programming

- Simpan durability pada instance item, sehingga tidak boleh digabung dengan instance durability berbeda.
- ThrownItem menyimpan persistent ID, posisi, dan durability.
- Instant kill hanya memanggil aturan pada musuh bertag small; jangan hardcode daftar nama musuh.
- Pastikan weight tidak hilang karena collision di luar bounds; sediakan recovery atau destruction yang jelas.

---

# 4. Interface Reaksi Bersama yang Dibutuhkan

Agar artifact tidak memerlukan kode khusus untuk setiap musuh, sistem berikut harus tersedia:

| Interface/Signal | Digunakan Oleh | Hasil |
| --- | --- | --- |
| `hear_sound(event)` | Rattlepod, Lantern Snail | AI menyelidiki, agitated, atau mengubah target |
| `apply_slow(amount, duration)` | Cling Resin, spider projectile | Mengubah movement tanpa mengedit script musuh |
| `apply_force(vector)` | Rock, Silver Weight, knockback | Mendorong body yang mendukung force |
| `apply_status(id, data)` | Bandage, Driftseed, poison, curse | Menambah/menghapus modifier melalui sistem status |
| `is_sight_blocked(from, to)` | Hushcap, terrain | Menentukan apakah AI dapat melihat target |
| `receive_thrown_impact(data)` | Rock, Silver Weight, item fisik | Damage, agitation, atau reaksi benturan |
| `is_small_enemy` tag/group | Silver Weight | Mengizinkan instant kill secara generik |
| `set_target_override(target, duration)` | Snail scream, spider mark | Mengubah prioritas target tanpa hardcode AI |

---

# 5. Kebutuhan UI Bersama

Setiap item harus dapat menampilkan:

- Icon
- Nama
- Jumlah stack
- Hotbar slot aktif
- Deskripsi dikenal/tidak dikenal
- Harga jual di toko saat ini
- Durability atau charge bila relevan
- Pesan ketika tidak dapat digunakan
- Indikator target valid bila item membutuhkan placement/attachment

Informasi yang harus terlihat khusus:

- Sisa waktu Numbing Pill
- Progres healing Bandage
- Pulsa tersisa Rattlepod jika dapat diambil kembali
- Cooldown/agitation Lantern Snail
- Durability Silver Weight
- Valid/tidak valid pemasangan Rope

---

# 6. Checklist Implementasi Setiap Item

Sebuah item dianggap selesai setelah:

- Resource data dan ID unik tersedia.
- Icon dan world sprite terpasang, minimal placeholder.
- Pickup, stack, hotbar, use, dan throw bekerja sesuai aturan.
- Konsumsi/retrieval bekerja tanpa duplikasi.
- Behavior bekerja pada pemain, terrain, dan musuh yang relevan.
- Harga permukaan dan Layer 2 benar.
- Deskripsi dikenal/tidak dikenal benar.
- Discovery use count tercatat bila item adalah relic.
- Autosave/Continue mempertahankan state yang wajib.
- Death dan New Game membersihkan state run dengan benar.
- Audio/VFX memiliki hook meskipun asset final belum tersedia.
- Item dapat diberikan melalui debug menu.
- Satu anggota tim lain sudah menjalankan uji penggunaan normal dan edge case.

---

# 7. Keputusan Desain yang Masih Perlu Dikunci

Keputusan berikut tidak menghalangi pembuatan prototype, tetapi harus diputuskan melalui playtest:

1. Apakah Multitool memakai hotbar atau tool slot terpisah.
2. Apakah item supply tanpa efek lempar boleh dilempar sebagai world pickup atau klik kanan dinonaktifkan.
3. Durasi final Sun Sphere, Hushcap, Cling Resin, dan Driftseed.
4. Jumlah pulsa final Rattlepod dan apakah pod kosong tetap menjadi object.
5. Cooldown teriakan Lantern Snail dan prioritasnya terhadap tracking mark spider.
6. Apakah penggunaan Numbing Pill kedua me-refresh atau menambah durasi.
7. Apakah Numbing Pill menghapus stack kutukan lama atau hanya mencegah stack baru. Saran awal: hanya mencegah stack baru.
8. Harga jual Silver Weight setelah lemparan pertama.
9. Apakah damage membatalkan healing Bandage.
10. Damage dan knockback final Throwable Rock.

Semua nilai tersebut harus berada di Resource atau Inspector agar dapat diubah tanpa mengedit logika item.
