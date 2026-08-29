# Delvers of the Abyss — Dokumen Desain Game

> **Status:** Sumber kebenaran desain pasca-game-jam yang terus diperbarui<br>
> **Versi:** 0.2 — 30 Agustus 2026<br>
> **Otoritas:** Versi English adalah sumber otoritatif. File ini adalah padanan bahasa Indonesianya.<br>
> **Status project:** Prototipe yang dapat dimainkan dan masih dikembangkan.

Dokumen ini menyimpan pengalaman pemain yang dituju dan rencana yang perlu dipertahankan selama development berlanjut. Dokumen ini membedakan behavior yang sudah tersedia, rencana masa depan yang telah dikonfirmasi, dan gagasan jangka panjang. Arsitektur teknis dan kontrak implementasi yang terperinci tetap berada di dokumen teknis terkait.

## Istilah status

| Label | Arti |
| --- | --- |
| **Sudah diimplementasikan** | Sudah ada di project dan akan dipertahankan. Bug atau masalah balance mungkin masih ada. |
| **Dikonfirmasi** | Arah desain sudah disetujui, tetapi belum tentu selesai atau dapat dimainkan. |
| **Provisional** | Solusi sementara yang berguna dan mungkin akan diganti nama atau didesain ulang. |
| **TBD** | Desain tidak boleh diciptakan sebelum diputuskan oleh pemilik project. |

---

## 1. Ringkasan eksekutif

### Konsep utama

*Delvers of the Abyss* adalah game eksplorasi sistemik 2D single-player dengan elemen roguelite dan extraction. Pemain turun ke Abyss yang sangat luas, bereksperimen dengan relic yang tidak biasa, menyiapkan jalur melewati terrain berbahaya, dan bertahan dari makhluk yang berinteraksi dengan sight, sound, force, status, item, dan makhluk lain. Perjalanan turun menciptakan kesempatan; membawa hasil penemuan kembali ke atas adalah inti ekspedisinya.

### Tagline publik

> Game roguelite eksplorasi 2D tentang turun ke dalam Abyss, beradaptasi dengan lingkungan, dan bertahan dalam perjalanan naik.

### Fantasi pemain

Pemain adalah Delver muda yang rapuh tetapi cerdik. Kekuatan berasal dari persiapan, pengetahuan, dan penggunaan alat secara kreatif—bukan dari banyak gerakan combat. Pemain yang berhasil akan mempelajari situasi, memilih barang yang dibawa, mengubah lingkungan, memanfaatkan behavior makhluk, dan meninggalkan jalur pulang yang dapat diandalkan sebelum turun lebih dalam.

### Target saat ini dan jangka panjang

- **Prototipe saat ini:** Surface hub dan Layer 1, berakhir ketika pemain mencapai gerbang Layer 2. Run yang berhasil saat ini memerlukan sekitar 15 menit.
- **Target rilis lengkap pertama:** Surface ditambah dua layer yang dapat dimainkan, dengan run normal yang berhasil sekitar 30 menit.
- **Visi jangka panjang:** passion project tanpa batas akhir kaku yang mungkin menambah layer unik dan akhirnya mendekati dasar Abyss. Visi ini bukan janji produksi.

### Inspirasi dan orisinalitas

Game ini memiliki setting original yang terinspirasi oleh:

- *Made in Abyss*: perjalanan turun, atmosfer, perjalanan naik yang berbahaya, dan progression menuju layer yang tidak dikenal;
- *Rain World*: ekologi, behavior makhluk, kerentanan pemain, dan suasana;
- *Spelunky*: susunan replayable yang berasal dari level design yang disengaja;
- *Risk of Rain 2*: loot berbasis run dan tekanan progression;
- *Noita* dan *Terraria*: alat sistemik, eksperimen, dan interaksi yang mengejutkan.

Istilah whistle rank dan Ascension Curse saat ini bersifat **provisional**. Istilah tersebut menjelaskan gameplay yang sedang digunakan, tetapi harus diubah menjadi lore dan penamaan original sebelum versi siap rilis. Game tidak boleh mengharuskan pemain memahami karya inspirasinya.

---

## 2. Pilar desain

### 2.1 Penggunaan relic secara kreatif

Relic adalah alat, bukan kunci dengan satu jawaban. Relic tidak menyelesaikan masalah dengan sendirinya; pengamatan dan cara penggunaan pemain yang membuatnya berguna. Relic yang kuat harus berinteraksi dengan beberapa bagian dunia atau menciptakan tradeoff, bukan hanya menjadi senjata.

**Tes desain:** jika item hanya memiliki satu target yang jelas dan tidak memiliki interaksi bermakna di luar target tersebut, item memerlukan peran sistemik yang lebih kuat.

### 2.2 Interaksi dunia dan makhluk

Makhluk adalah bagian dari lingkungan, bukan rintangan combat yang berdiri sendiri. Sight, sound, cahaya, terrain, loose item, force, status effect, dan spesies lain memengaruhi behavior. Setiap enemy baru harus mengisi niche yang jelas atau menggabungkan niche lama dengan cara baru.

**Tes desain:** encounter harus menawarkan pengamatan, penghindaran, distraction, manipulation, atau route planning selain direct damage.

### 2.3 Eksperimen menjadi pengetahuan

Pemain hanya mengetahui informasi yang terlihat jelas saat pertama menemukan relic. Penggunaan relic mengungkap fungsinya dan mengubah eksperimen pemain menjadi pengetahuan persisten. Penggunaan yang salah tetap dapat menghabiskan item jika fiction dan aturannya menuntut demikian; discovery memiliki risiko.

**Tes desain:** eksperimen harus menghasilkan akibat yang dapat dipahami meskipun bukan hasil yang diinginkan pemain.

### 2.4 Rencanakan perjalanan pulang

Perjalanan turun hanya separuh perjalanan. Penempatan Rope, supplies, inventory weight, health, posisi makhluk, dan Ascension Curse membuat perencanaan pulang menjadi aktivitas inti. Jalur yang aman saat turun dapat menjadi berbahaya ketika digunakan untuk naik.

**Tes desain:** level harus menciptakan setidaknya satu keputusan jalur pulang yang bermakna sebelum memberikan hadiah untuk bergerak lebih dalam.

### Anti-pilar

Game ini tidak ditujukan untuk menjadi:

- platformer yang berfokus pada combat atau game action-combat tradisional;
- Metroidvania yang berfokus pada upgrade pergerakan permanen;
- game dengan class system atau base building;
- game progression yang membutuhkan grinding berat;
- game dengan terrain prosedural;
- game yang sengaja menghukum melalui kegagalan yang tidak jelas atau tidak dapat dihindari;
- simulasi dengan kompleksitas AI atau animasi yang lebih mahal daripada nilai yang dirasakan pemain.

---

## 3. Audiens dan pengalaman yang dituju

### Audiens

Critical path ditujukan kepada pemain umum yang pernah memainkan setidaknya satu platformer. Penguasaan sistem yang lebih dalam harus memberi hadiah kepada pemain yang menyukai game eksperimental dan berbasis ekologi, tetapi penyelesaian dasar tidak boleh membutuhkan pengalaman khusus dengan genre tersebut.

Game dibuat dalam English terlebih dahulu dengan localization Indonesia. Dialogue bersifat kasual, sedikit, dan ditujukan untuk remaja atau pemain yang lebih tua.

### Alur emosi

| Tahap ekspedisi | Perasaan yang dituju |
| --- | --- |
| Persiapan di Surface | Rasa ingin tahu dan antisipasi |
| Perjalanan turun pertama | Kekaguman dengan ketidakpastian yang terkendali |
| Encounter makhluk | Waspada, mengamati, dan tertekan |
| Menemukan relic | Eksperimen dan kegembiraan |
| Keputusan inventory atau jalur | Pengorbanan yang dipikirkan |
| Perjalanan naik | Terrain lama yang menjadi berbahaya kembali |
| Pulang dengan aman | Lega, merasa memiliki hasil, dan siap memperbaiki rencana berikutnya |
| Gerbang lebih dalam | Ingin mengetahui apa yang ada selanjutnya |

### Kesulitan dan fairness

Kesulitan terutama berasal dari resource planning, route planning, kombinasi makhluk, dan risiko perjalanan naik. Ancaman harus dapat dibaca. Gerakan dengan damage atau knockback tinggi membutuhkan warning yang terlihat. Loading, perpindahan section, dan serangan dari luar layar tidak boleh menciptakan damage yang mustahil dihindari.

Hanya kematian yang mengakhiri run. Pemain tidak boleh mengalami softlock permanen akibat item hilang, quest gagal, atau jalur yang tidak dapat dicapai. Direct combat dapat membuat area lebih aman atau memberikan keuntungan situasional, tetapi makhluk biasa tidak menjatuhkan loot dan tidak memberikan insentif farming.

Kekerasan tetap bergaya dan tidak grafis. Karakter dapat memukul atau menembak makhluk, dan sedikit efek darah dapat muncul, tetapi luka grafis berada di luar tone yang dituju.

---

## 4. Scope produk dan status saat ini

### 4.1 Build yang dapat dimainkan — Sudah diimplementasikan

Pemain dapat:

1. memulai run baru di Surface;
2. memperoleh atau membeli supplies ekspedisi dasar;
3. memilih pintu masuk timur atau barat menuju Layer 1;
4. melewati susunan section buatan tangan yang dipilih berdasarkan seed;
5. menemukan dan menggunakan relic Layer 1;
6. menghindari, memanipulasi, atau membunuh makhluk Layer 1;
7. menempatkan Rope dan menyiapkan jalur naik;
8. mengalami dan mengelola Ascension Curse Layer 1;
9. kembali untuk menjual penemuan dan membeli supplies, atau melanjutkan turun;
10. melewati, mengakali, mengalihkan, atau melawan gatekeeper Layer 1;
11. menyelesaikan prototipe dengan mencapai gerbang Layer 2.

Mechanic, item, dan enemy Layer 1 sudah diimplementasikan secara substansial. Layer 1 belum dianggap selesai secara konten sampai semua section variation barat dan timur selesai dibuat, didekorasi, diseimbangkan, dan dapat dimainkan dengan bug minimal.

### 4.2 Milestone berikutnya — Dikonfirmasi

Urutan development:

1. selesaikan section variation barat Layer 1;
2. selesaikan section variation timur Layer 1;
3. seimbangkan dan stabilkan run Layer 1 yang lengkap;
4. mulai vertical slice Layer 2 yang dapat dimainkan;
5. selesaikan dan rilis slice stabil satu layer setiap tahap.

Penyelesaian Layer 1 adalah prioritas tertinggi setelah dokumentasi ini.

### 4.3 Layer 2 — Desain dikonfirmasi, konten belum selesai

Dokumen implementasi Layer 2 saat ini mengonfirmasi empat relic—Plate Umbrella, Lacerator, Resonance Core, dan Bolt Shock—serta lima kategori makhluk—Canopy Primate, Tremor Hound, Carrion Stalker, Bulwark Beast, dan Sky Hunter Flock. Fondasi mereka sudah tersedia, tetapi map final, presentation, balance, integrasi narrative, dan layer lengkap yang dapat dimainkan belum selesai.

Layer 2 adalah titik tempat sistem yang diperkenalkan dengan aman di Layer 1 mulai menghasilkan kombinasi yang lebih menantang. Layer ini dapat memakai struktur dunia yang sangat berbeda; layout dua rute dan enam slot pada Layer 1 adalah batasan game jam, bukan template wajib untuk semua layer.

### 4.4 Setelah Layer 2 — TBD

Rilis lengkap pertama dibatasi menjadi dua layer yang dapat dimainkan. Layer berikutnya, peran Layer 3, dasar Abyss, dan ending final masih menjadi pekerjaan desain jangka panjang. Semua itu dapat memperluas passion project nanti, tetapi tidak boleh memperbesar scope jangka dekat.

### 4.5 Konten sementara

Hal berikut tidak boleh dianggap sebagai arah final:

- seluruh audio saat ini;
- sebagian asset karakter, background, dan interface;
- asset buatan AI yang ditandai untuk kemungkinan penggantian;
- implementasi quest dan teks dialogue saat ini;
- map yang belum selesai atau belum didekorasi;
- istilah dan lore pinjaman yang masih provisional.

Model world generation berbasis authored section akan dipertahankan, meskipun layer berikutnya dapat menggunakan section yang lebih besar, jumlah section lebih banyak, atau struktur berbeda.

---

## 5. Gameplay inti

### 5.1 Loop dari saat ke saat

1. **Amati:** baca terrain, exit, loose object, makhluk, cahaya, dan anchor yang tersedia.
2. **Persiapkan:** pilih arah, siapkan relic, atau tempatkan Rope sebelum berkomitmen.
3. **Lewati:** bergerak, melompat, memanjat, dan mengelola weight melalui geometry yang dibuat dengan sengaja.
4. **Berinteraksi:** alihkan, perlambat, terangi, ikat, tandai, lempar, curi dari, atau beri damage kepada actor melalui sistem bersama.
5. **Pulihkan keadaan:** kumpulkan item berguna, buat jarak, tangani effect, dan evaluasi ulang jalur pulang.
6. **Lanjutkan atau mundur:** gunakan resource untuk pergi lebih dalam atau ubah value dan knowledge menjadi run berikutnya yang lebih aman.

### 5.2 Loop ekspedisi

1. Mulai di Surface dengan Multitool dan money yang tersedia.
2. Kunjungi shop, beli supplies, dan gunakan loot Surface yang dimaksudkan untuk membantu persiapan.
3. Pilih pintu masuk timur atau barat. Rute memberikan variasi tanpa menjanjikan progression atau reward yang sangat berbeda.
4. Turun melalui section terpilih, kumpulkan relic, dan tempatkan Rope di lokasi yang akan berbahaya saat pulang.
5. Akali makhluk menggunakan alat yang dibawa, dengan menerima bahwa semua object berguna tidak dapat dibawa sekaligus.
6. Pilih antara bergerak lebih dalam dan pulang berdasarkan health, ruang inventory, weight, supplies tersisa, ancaman yang diketahui, dan keamanan jalur.
7. Naik melalui jalur yang telah disiapkan sambil mengelola batas Curse dan makhluk dalam konteks terrain yang terbalik.
8. Kembali ke Surface, jual relic, beli supplies, periksa description yang dipelajari, dan rencanakan run berikutnya—atau lanjutkan turun tanpa mengambil keuntungan terlebih dahulu.

Kembali ke Surface adalah soft pressure, bukan timer. Kelemahan, health rendah, inventory penuh, weight, dan supplies yang habis mendorong pemain untuk pulang. Curse dibuat agar perjalanan naik memiliki tantangan sendiri, bukan untuk memaksa jadwal pulang tertentu.

### 5.3 Contoh run yang mewakili game

Run Layer 1 yang ideal dimulai dengan beberapa Rope dan pilihan rute yang disengaja. Pemain menemukan relic berguna tetapi belum dikenal, menggunakan sound atau terrain untuk menghindari satu makhluk, lalu menggabungkan relic kedua dengan behavior enemy untuk melewati encounter lain. Pemain menempatkan Rope sebelum jatuhan panjang, meninggalkan item berharga karena weight dan slot penting, lalu menggunakan Rope tersebut untuk membagi perjalanan naik menjadi waktu istirahat yang aman. Mendekati Surface, pemain memilih apakah akan mengambil satu risiko tambahan atau melindungi value yang sudah dibawa.

Momen yang paling mewakili game bukan membunuh makhluk. Momen tersebut adalah ketika pemain menyadari bahwa relic, makhluk, dan terrain membentuk solusi yang tidak pernah ditentukan secara eksplisit oleh game.

---

## 6. Run progression, persistence, dan economy

### Run state

Living run mempertahankan section yang dihasilkan, hasil placer, world item, kematian dan health makhluk, item yang dibawa, money, status whistle, effect relevan, dan progression flag melalui Save & Continue. Projectile sementara, fase attack aktif, dan effect area singkat dipulihkan ke state aman, bukan dilanjutkan di tengah collision.

### Kematian

Kematian adalah satu-satunya kegagalan yang mengakhiri run. Kematian mereset run inventory, money, world state, route state, dan run progression. Meta knowledge persisten bertahan melalui item description yang ditemukan, bersama statistik lifetime tertentu. Save & Continue biasa bukan kematian dan mempertahankan living run.

Fiction yang menjelaskan knowledge setelah mati masih **TBD**. Sampai ditulis, GDD menganggap description persisten sebagai pemahaman pemain yang terkumpul, bukan kekuatan supernatural karakter.

### Progression permanen

Progression permanen harus menekankan:

- relic knowledge dan description;
- access dan whistle rank;
- story dan dialogue flag;
- service atau route yang dibuka jika diperlukan;
- statistik non-power dari run sebelumnya.

Grinding stat permanen bukan bagian dari visi saat ini.

### Economy

Money saat ini digunakan untuk membeli supplies ekspedisi. Sale value memberi alasan untuk membawa pulang penemuan berguna, bukan menghabiskan semuanya. Sistem delivery dan quest masih provisional dan tidak boleh menjadi grinding wajib tanpa keputusan desain berikutnya.

Economy harus menjawab satu pertanyaan: **resource apa yang membuat ekspedisi berikutnya lebih aman atau fleksibel?** Money yang tidak dapat mengubah persiapan tidak memiliki peran bermakna.

### Replay value

Replay berasal dari, berdasarkan prioritas:

1. kombinasi relic yang berbeda;
2. variasi rute dan section;
3. encounter makhluk sistemik;
4. relic knowledge yang belum lengkap;
5. objective opsional dan planning yang lebih efisien.

---

## 7. Pemain, kontrol, dan inventory

### Kemampuan pemain

Pemain dapat berlari, melakukan variable jump, mengarahkan gerakan di udara, berinteraksi melalui cursor, menggunakan atau melempar item terpilih, menempatkan dan memanjat Rope, mengelola inventory, serta menggunakan whistle fisik. Gerakan tetap mudah dipahami; penguasaan item dan environment menyediakan sebagian besar ekspresi tingkat lanjut.

### Kontrol

| Aksi | Input default |
| --- | --- |
| Bergerak | `A` / `D` atau panah kiri/kanan |
| Lompat | `Space` |
| Bergerak di Rope | `W` / `S` atau panah atas/bawah |
| Interaksi / mengambil item | `E` |
| Aksi utama item | Tombol kiri mouse |
| Aksi kedua item | Tombol kanan mouse |
| Memilih hotbar | `1`, `2`, atau roda mouse |
| Inventory | `Tab` |
| Pause / menutup | `Esc` |
| Fullscreen | `F11` |

Keyboard dan mouse sudah diimplementasikan. Controller support direncanakan, tetapi belum dikonfirmasi sampai model interaction dan cursor memiliki padanan controller yang teruji.

### Inventory

- Lima slot backpack.
- Dua slot hotbar khusus.
- Satu slot whistle fisik.
- Aturan stack bergantung pada item dan mutable state-nya.
- Item weight memengaruhi movement, jump, falling, throwing, dan keputusan membawa pulang atau meninggalkan sesuatu.

Inventory kecil ini disengaja dan tidak boleh diperbesar tanpa pertimbangan. Pemain harus membandingkan kegunaan langsung, keamanan masa depan, sale value, dan weight. Upgrade kapasitas belum direncanakan.

### Aksi item

Klik kiri meminta primary behavior item terpilih. Klik kanan meminta secondary behavior yang eksplisit, sering kali physical throw. Item dapat mengganti atau menonaktifkan salah satu aksi. Item nyata mempertahankan identitas dan state di dunia; attack sementara menggunakan projectile yang tidak dapat diambil.

### Rope

Rope adalah perlengkapan traversal dan ingatan jalur. Placement menggunakan resource terbatas pada suatu lokasi, membuat jalur pulang, bertahan selama living run, dan dapat dipanjat ketika memegang item aktif. Map harus menyediakan keputusan anchor yang berharga tanpa mewajibkan satu placement tertentu.

---

## 8. Struktur dunia dan generation

### Surface

Surface adalah hub persiapan dan recovery. Surface berisi shop, supplies awal, fungsi dialogue/NPC, kedua pintu masuk Layer 1, dan service progression. Tempat ini harus terasa lebih aman dan mudah dibaca dibanding Abyss tanpa menghilangkan antisipasi perjalanan turun.

### Variasi authored

Terrain dibuat dengan tangan. Seed memilih section variation dan hasil placer deterministik; seed tidak membuat terrain secara prosedural. Hal ini mempertahankan traversal dan komposisi encounter yang disengaja sekaligus memberikan rute dan susunan item/enemy berbeda pada run berikutnya.

Untuk struktur Layer 1 saat ini:

- rute timur dan barat masing-masing menggunakan enam section slot;
- setiap slot memilih variation buatan tangan yang kompatibel;
- terrain, entrance, exit, safe position, dan actor progression utama tetap diatur secara sengaja;
- placer menentukan enemy atau loot yang valid dari entry yang dikontrol designer;
- konten unik yang wajib menggunakan allocation rule agar setiap susunan dapat diselesaikan;
- pemain selalu mulai di Surface.

Rute timur dan barat memberikan variasi, tetapi saat ini tidak ditujukan untuk memiliki identitas atau progression reward yang sangat berbeda.

### Layer masa depan

Layer berikutnya dapat menggunakan jumlah rute berbeda, section lebih besar, section tambahan, hub, atau struktur traversal lain. Layer tersebut harus mempertahankan authored readability, save deterministik, dan perlindungan terhadap softlock. Kompleksitas world generation baru membutuhkan manfaat yang jelas bagi pemain sebelum diterima.

---

## 9. Relic dan supplies

### Filosofi item

Setiap relic adalah object fisik dengan beberapa value: penggunaan langsung, potensi interaksi, keamanan jalur, sale value, delivery value, weight, dan knowledge. Relic baru layak ditambahkan ketika menciptakan keputusan atau interaksi yang tidak dapat disediakan alat lama dengan baik.

Pemain awalnya hanya menerima informasi yang terlihat jelas. Signature use yang berhasil mengungkap description item discoverable. Penggunaan yang salah masih dapat menghabiskan consumable; risiko membuat eksperimen bermakna.

### Roster Layer 1 — Sudah diimplementasikan

| Item | Peran desain utama |
| --- | --- |
| Multitool | Tool/attack jarak dekat reusable dan interaction dengan breakable; tidak dapat dilempar. |
| Rope | Persiapan jalur persisten dan climbing. |
| Rock | Referensi physical force dan throwing sederhana. |
| Bandage | Menghapus Bleed dan menerapkan Healing yang dapat bertambah hingga batas durasi. |
| Info Book | Mengungkap description discoverable yang tersisa. |
| Numbing Pill | Menekan threshold Curse sementara dengan biaya durasi tambahan. |
| Sun Sphere | Cahaya bergerak yang dapat diaktifkan sebelum atau melalui impact sambil mempertahankan momentum dunia. |
| Lantern Crystal | Flash line-of-sight dan sound lure yang dapat dilempar serta diperoleh dari Lantern Snail. |
| Rattlepod | Sumber sound berulang dengan priority tinggi untuk distraction dan targeting. |
| Hushcap | Cloud penekan sight dengan feedback overlay pemain. |
| Cling Resin | Area perlambatan biru yang mengendalikan actor dan gerakan loose object. |
| Driftseed | Mengubah descent, gravity, knockback, dan target flying yang valid. |
| Silver Weight | Tool sangat berat dengan impact tinggi, state rusak yang terlihat, dan penggunaan terbatas. |
| Red / Blue Whistle | Item rank fisik dan sumber sound priority tinggi. Istilah masih provisional. |

### Roster Layer 2 — Dikonfirmasi, belum selesai

| Relic | Peran yang dituju |
| --- | --- |
| Plate Umbrella | Pertahanan mengikuti cursor yang menukar mobility dan stability untuk perlindungan. |
| Lacerator | Projectile gravity dengan ammunition terbatas yang menciptakan bola berbahaya persisten dan Bleed. |
| Resonance Core | Quest relic unik dan berat dengan impact yang menciptakan sound dan force bertingkat. |
| Bolt Shock | Reward weapon dengan penggunaan terbatas yang menginterupsi, menyetrum, menekan sensor, dan menonaktifkan flight. |
| Moon Whistle | Credential progression fisik provisional yang terhubung dengan exchange Layer 2. |

Acquisition, quest, dan reward flow Layer 2 masih dapat berubah saat narrative dan map diintegrasikan. Behavior teknis saat ini sudah didokumentasikan; hal tersebut bukan bukti bahwa layer sudah selesai sebagai konten.

---

## 10. Makhluk dan desain encounter

### Filosofi bersama

Makhluk menyampaikan intent melalui movement, facing, animation, telegraph, sound, dan sensor yang terlihat melalui debug saat development. Setiap spesies memiliki niche yang mudah dikenali. Membunuh makhluk menghilangkan bahaya, tetapi biasanya tidak memberikan loot. Solusi non-combat harus tetap tersedia pada rute wajib.

Behavior makhluk menggunakan kontrak bersama untuk health, damage, force, effect, sight, sound, target priority, persistence, dan hit feedback. Logic khusus spesies harus tetap sesederhana behavior yang terlihat; project tidak mencoba membuat AI prosedural dengan simulasi berat.

### Makhluk Layer 1 — Sudah diimplementasikan

| Makhluk | Niche encounter |
| --- | --- |
| Tongue Amphibian | Roaming, menyelidiki sound, memilih loose item, dan dapat mencuri satu item nyata pemain. |
| Knockback Bird | Melindungi sarang dan menjadikan terrain danger sebagai ancaman utama melalui swoop force. |
| Thorn Bloom | Hazard netral dan diam yang meledak menjadi needle radial penyebab Bleed ketika diagitasi. |
| Lantern Snail | Merayap di surface yang tersambung, menghindari pemain, memancarkan cahaya, dan menghasilkan respons flash/sound dengan line of sight. |
| Cave Spider | Menggunakan sound dan sight, menembakkan projectile Slowness/Poison/Tracked, mengejar target untuk menggigit, lalu retreat. |
| Large Flyer | Hunter persisten seluruh layer yang mengamati, mencari, mengejar, dan berkomitmen pada dive dengan damage tinggi. |
| Senior Diver | Encounter gatekeeper dengan pilihan credential, dialogue, distraction, bypass, grab/confiscation, atau combat. |

### Makhluk Layer 2 — Dikonfirmasi, belum selesai

| Makhluk | Niche encounter |
| --- | --- |
| Canopy Primate | Menjaga jarak di ground dan melempar gravity rock secara terkoordinasi. |
| Tremor Hound | Menemukan sumber sound, mencari melalui terrain, mengonfirmasi prey dekat, dan melakukan pounce. |
| Carrion Stalker | Memilih prey yang terluka, Bleeding, Poisoned, atau memiliki health rendah. |
| Bulwark Beast | Memberikan telegraph lalu berkomitmen pada horizontal charge kuat dengan recovery window. |
| Sky Hunter Flock | Beberapa flyer yang dapat menerima damage secara mandiri dan dikoordinasikan melalui attack spacing serta persistence bersama. |

Layer 2 harus menggabungkan niche ini, bukan hanya meningkatkan health dan damage.

---

## 11. Interaksi sistemik, effect, dan Curse

### Bahasa interaksi bersama

Game harus mengutamakan kata kerja bersama daripada solusi scripted satu kali:

- **Damage:** mengurangi health dan dapat membunuh.
- **Force:** mengubah movement dan dapat membuat terrain berbahaya tanpa damage.
- **Sight:** membutuhkan range, facing jika digunakan, dan garis tanpa hambatan menuju detection point pemain.
- **Sound:** membawa position, radius, dan priority sehingga dapat memicu investigation atau target override.
- **Status:** mengubah actor selama durasi tertentu dan tetap terlihat melalui teks/timer.
- **Agitation:** membuat makhluk atau hazard netral bereaksi tanpa mengubah semua respons menjadi chase.
- **World ownership:** membuat item nyata tetap dapat diambil, dicuri, dijual, dan disimpan.

Kontrak ini memungkinkan satu alat memengaruhi beberapa makhluk tanpa custom code untuk setiap pasangan.

### Effect

Effect penting meliputi Bleed, Poison, Slowness, Resin Bound, Incapacitated, Tracked, Dazzled, Healing, Curse Suppression, Driftseed, Electrocuted, dan package Curse khusus layer.

- Durasi Poison berulang bertambah hingga 15 detik.
- Durasi Slowness dari spider bertambah hingga 10 detik.
- Durasi Tracked berulang bertambah hingga 20 detik.
- Healing dari Bandage bertambah hingga 50 detik.
- Tick damage menghasilkan satu hit flash; direct damage menghasilkan dua flash cepat pada pemain.
- Enemy menampilkan teks effect aktif dan durasinya di atas kepala.
- Hushcap mencegah sight detector enemy memperbarui deteksi selama terkena effect.
- Effect listrik menginterupsi kemampuan makhluk yang sesuai: frog tidak dapat melompat atau mencuri, spider tidak dapat menembak, dan flyer yang dinonaktifkan akan jatuh.

Nilai angka tetap data-driven dan dapat berubah saat balancing.

### Ascension Curse

Curse mengubah perjalanan naik menjadi tekanan route dan pacing. Sistem melacak titik terdalam pemain dan menerapkan package ketika pemain melewati ascent band baru. Beristirahat pada ketinggian yang hampir sama mereset reference; safe zone meresetnya secara sengaja. Numbing Pill melewati threshold dengan aman tetapi menggunakan durasi suppression.

Layer 1 saat ini menerapkan package sementara yang memengaruhi movement, healing, throw reach, dan color. Layer 2 memiliki package terpisah yang sudah dikonfirmasi berupa penalty throw/color, stack health cap sementara, dan interruption movement sesekali. Package antarlayer tidak digabungkan.

Warning memberi tahu pemain ketika gerakan ke atas mencapai 70% dari threshold Curse berikutnya. Hal ini membuat kegagalan dapat dibaca tanpa menghapus kebutuhan merencanakan waktu istirahat.

Penyebab Curse dalam dunia, pengetahuan masyarakat, dan nama final masih **TBD**. Untuk saat ini Curse dianggap sebagai sifat alami Abyss dan bahaya pekerjaan yang sudah dikenal.

---

## 12. Narrative dan dunia

### Premis

Masyarakat tinggal di tepi Abyss karena pengambilan relic menjadi dasar economy mereka. Artifact dijual kepada negara lain sehingga perjalanan turun tetap menjadi mata pencaharian meskipun berbahaya. Relic dipercaya berasal dari peradaban masa lalu, tetapi pembuatnya dan sifat asli Abyss belum diketahui.

Protagonist turun untuk pertama kalinya tanpa pengawasan karena rasa ingin tahu, misteri Abyss, dan warisan orang tua yang hilang—seorang Delver legendaris yang pergi ke tempat yang mungkin mustahil ditinggalkan kembali.

### Protagonist — Provisional

Build game jam menyebut protagonist **Elenara**. Nama ini bukan nama final. Personality, umur, dan arc jangka panjang masih **TBD**. Arah yang sudah ditetapkan:

- ia adalah anak muda dengan rasa ingin tahu yang mulai melakukan perjalanan tanpa pengawasan;
- ia hanya memiliki sedikit pengetahuan praktis tentang relic di awal;
- orang tuanya adalah Delver legendaris;
- ia dipercayakan kepada seorang mentor tua;
- dialogue tetap sedikit dan kasual, bukan exposition tanpa henti.

### Old Man

Old Man adalah mantan anggota kelompok Delver milik orang tua protagonist. Orang tua tersebut mempercayakan anaknya kepadanya. Sekarang ia melatih dan membimbing Delver baru, tetapi menolak menjelaskan alasan pensiun atau seluruh hal yang diketahuinya. “The Wanderer” adalah identitas placeholder dan bukan canon.

### Shopkeeper Surface

Shopkeeper saat ini secara fungsi hanya merupakan seller NPC. Nama, personality, hubungan, dan tujuan ceritanya masih **TBD**.

### Gatekeeper Layer 1

Gatekeeper adalah Delver berpengalaman dengan rank Blue provisional yang dipercaya mengamankan perjalanan masuk dan keluar Layer 2. Encounter mendukung beberapa pendekatan karena kebebasan pemain adalah nilai inti: rank yang diakui, dialogue, distraction, bypass, direct conflict, atau menerima grab dan confiscation dari gatekeeper.

### Authority Layer 2

Delver legendaris kedua direncanakan sebagai authority misterius di Layer 2 yang mengetahui informasi tentang orang tua protagonist. Exchange Resonance Core opsional dan reward saat ini memberikan fondasi fungsional, tetapi characterization, dialogue, dan makna quest final masih **TBD**.

### Penyampaian narrative

Cerita terutama disampaikan melalui dialogue singkat, environment, item description, behavior makhluk, dan discovery pemain. Aturan wajib tidak boleh hanya disembunyikan di flavor text. Cutscene harus jarang digunakan dan hanya untuk informasi yang tidak dapat disampaikan gameplay.

Semua dialogue saat ini melayani fungsi prototipe dan belum menjadi canon final. Shadow adalah placeholder dan tidak boleh muncul sebagai karakter canon terpisah tanpa desain baru.

### Ending — TBD

Rilis lengkap pertama harus memiliki stopping point Layer 2 yang memuaskan, tetapi ending pastinya belum dirancang. Ambisi jangka panjang adalah mencapai dasar Abyss; kebenaran tentang dasar tersebut dan nasib orang tua yang hilang tidak boleh diciptakan sebelum pekerjaan narrative dilanjutkan.

---

## 13. Presentation, UI, audio, dan accessibility

### Arah visual

Dunia yang dituju bersifat fantastical-medieval dengan unsur science fiction dan speculative biology. Makhluk pada layer atas dimulai dengan bentuk alami yang mudah dikenali; makhluk lebih dalam dapat menjadi semakin asing. Environment harus menciptakan kekaguman, skala, keindahan, dan bahaya sambil mempertahankan silhouette object interaktif dan telegraph ancaman yang mudah dibaca.

Project saat ini menggunakan pixel art dengan internal viewport 640×360 dan nearest-neighbor rendering. Resolution dan pipeline art ini adalah batasan yang sudah diimplementasikan, tetapi masing-masing asset masih dapat diganti.

### Interface

Interface harus terasa sebagai object dari dunia ekspedisi sambil tetap mudah dibaca. Inventory seperti buku dan bahasa visual menu bergambar saat ini adalah arah yang disukai. HUD menyampaikan health, selected item, whistle, money, weight, active effect, interaction prompt, Curse warning, dan telegraphed threat.

### Feedback

- Direct damage pemain: dua white flash cepat; tick damage: satu flash.
- Damage enemy: satu white flash dengan durasi adjustable.
- Health bar menggunakan pola flash direct/tick yang sama.
- Aksi enemy berisiko tinggi menampilkan warning icon dan enemy pointer terarah.
- Status aktif menampilkan nama dan durasi.
- Debug F3 dapat menampilkan sensor, patrol range, hitbox, health, state, sound target, world generation, dan test control terpilih tanpa memaksa semua range aktif bersamaan.

### Audio

Seluruh audio saat ini bersifat sementara. Arah sound final masih **TBD**. Soundscape yang dituju harus terasa luas, menakjubkan, dan misterius. Music nantinya harus adaptif. Movement, sound source, relic activation, telegraph, impact, dan respons makhluk yang penting untuk gameplay harus tetap dapat dikenali bahkan sebelum final music tersedia.

### Accessibility

Arah yang dikonfirmasi tetapi belum selesai:

- teks dan telegraph yang mudah dibaca;
- informasi penting tidak disampaikan hanya melalui color;
- opsi untuk mengurangi flash dan screen effect;
- camera shake, parallax, dan pixel movement yang dibatasi agar tidak menyebabkan mual;
- investigasi input remapping dan controller pada masa depan;
- subtitle/teks untuk informasi audio penting jika memungkinkan.

Scope accessibility masih provisional dan harus berkembang melalui playtesting, bukan melalui janji yang belum dapat didukung project.

---

## 14. Arah produksi

### Model development

Development terutama dilakukan solo, dengan bantuan sesekali dari anggota tim game jam. Pemilik project memiliki keputusan akhir untuk design, narrative, programming, art direction, dan release. Contributor dapat mengusulkan perubahan, tetapi update GDD yang disetujui menentukan behavior yang dituju untuk pemain.

### Kebijakan milestone

Buat vertical slice stabil satu layer setiap tahap dan pertahankan branch main agar dapat dimainkan. Jangan membuat sistem jangka panjang hanya karena layer masa depan mungkin membutuhkannya. Pilih solusi authored sederhana daripada kompleksitas simulasi ketika keduanya menghasilkan pengalaman pemain yang dituju.

### Risiko utama

1. Beban kerja solo.
2. Produksi asset dan biaya penggantian.
3. Technical debt yang bertambah.
4. Volume konten yang dibutuhkan oleh map variation buatan tangan.
5. Menyeimbangkan interaksi tanpa membuatnya sulit dibaca.

### Playtesting

Teman dan collaborator adalah kelompok test awal. Testing harus menjawab:

- Apakah pemain baru memahami cara memulai ekspedisi?
- Apakah mereka dapat menemukan setidaknya satu solusi non-combat untuk enemy?
- Apakah mereka memahami alasan interaksi item berhasil atau gagal?
- Apakah penempatan Rope berguna saat perjalanan pulang?
- Apakah Curse menciptakan planning, bukan kebingungan?
- Apakah mereka dapat mencapai endpoint saat ini tanpa debug tool atau softlock?
- Apakah movement, pixel rendering, flash, atau overlay menyebabkan rasa tidak nyaman?

Feedback presentasi menyatakan project memiliki potensi tetapi tidak mudah untuk mulai dipahami. Karena itu onboarding dan clarity lebih penting daripada menambah konten baru.

### Kesuksesan

Project berhasil jika menjadi game yang selama ini ingin dibuat pemiliknya dan menciptakan pengalaman berkesan bahkan untuk sedikit pemain. Skala komersial tidak diwajibkan. Kebanggaan kreatif, identitas sistemik yang koheren, dan rilis stabil yang dapat dimainkan adalah hasil sukses yang sah.

---

## 15. Daftar desain terbuka

Hal berikut sengaja belum diselesaikan:

- nama, umur, personality, dan voice protagonist final;
- sifat dan asal-usul Abyss;
- pengganti original untuk whistle rank dan istilah Curse pinjaman;
- sejarah lengkap dan nasib orang tua yang hilang;
- identitas final shopkeeper Surface;
- authority Layer 2, narrative quest, dan reward final;
- struktur dan map final Layer 2;
- stopping point dan ending Layer 2;
- komitmen untuk Layer 3 atau layer lebih dalam yang dapat dimainkan;
- arah music dan audio final;
- pengaturan motion effect dan accessibility;
- credit contributor, attribution pihak ketiga, dan URL itch.io;
- rencana penggantian asset sementara dan buatan AI.

Jangan mengubah `TBD` menjadi canon hanya karena implementation memerlukan label. Gunakan placeholder provisional yang jelas dan kembalikan keputusan narrative/design ke daftar ini.

---

## 16. Otoritas dokumen dan referensi

Jika dokumen bertentangan:

1. GDD ini memiliki otoritas untuk intent yang dirasakan pemain dan sudah disetujui.
2. `fondasi_teknis_godot.md` memiliki otoritas untuk arsitektur teknis bersama.
3. `panduan_programming.md` memiliki otoritas untuk workflow implementation dan aturan code.
4. `panduan_world_generation.md` memiliki otoritas untuk kontrak authoring map dan placer.
5. `docs/implementation/` memiliki otoritas untuk kontrak enemy, item, effect, Curse, dan Layer 2 yang sudah diimplementasikan.
6. Questionnaire yang telah dijawab menyimpan riwayat keputusan.
7. `docs/reference/` adalah arsip dan tidak dapat menggantikan keputusan terbaru.

Perbedaan tidak sengaja antara code dan dokumen ini adalah bug, bukan perubahan desain otomatis. Perubahan yang disengaja harus memperbarui GDD dan dokumen implementation terkait dalam checkpoint yang sama setelah persetujuan pemilik.

Referensi utama:

- [Fondasi teknis](fondasi_teknis_godot.md)
- [Panduan programming](panduan_programming.md)
- [Panduan world generation](panduan_world_generation.md)
- [Item Layer 1](implementation/layer_1_items.md)
- [Enemy Layer 1](implementation/layer_1_enemies.md)
- [Ascension Curse](implementation/ascension_curse.md)
- [Effect](implementation/effects.md)
- [Relic Layer 2](implementation/layer_2_relics.md)
- [Enemy Layer 2](implementation/layer_2_enemies.md)
- [Integrasi dunia Layer 2](implementation/layer_2_world_integration.md)

Rekonsiliasi penuh dokumentasi teknis dijadwalkan sebagai audit terpisah setelah pass GDD/README ini.
