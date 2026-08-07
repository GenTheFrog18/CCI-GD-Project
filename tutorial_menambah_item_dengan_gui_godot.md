# Tutorial Menambah dan Memprogram Item melalui GUI Godot

Tutorial ini ditujukan untuk programmer yang hampir belum pernah memakai Godot. Versi project yang digunakan adalah **Godot 4.7.1**.

Target tutorial:

1. memahami bagian GUI Godot yang dipakai sehari-hari,
2. membuat item baru tanpa mengubah sistem inventory,
3. memakai behavior lempar yang sudah tersedia,
4. membuat primary behavior sederhana jika item memang membutuhkannya,
5. menguji pickup, hotbar, primary, secondary, dan error melalui GUI,
6. menyerahkan perubahan yang kecil dan aman untuk direview.

Jangan mulai dari item paling kompleks. Selesaikan satu item sederhana dari data sampai dapat dimainkan, lalu gunakan workflow yang sama untuk item berikutnya.

---

# 1. Aturan paling penting sebelum mulai

Untuk task item biasa, file yang boleh disentuh adalah:

```text
data/items/<item_id>.tres
game/items/behaviors/<item_id>_behavior.gd   # hanya jika behavior baru diperlukan
art/items/...                                 # jika asset sudah tersedia
tests/foundation_smoke.gd                     # assertion minimum
```

Jangan mengedit file berikut tanpa persetujuan lead:

```text
game/player/player.gd
game/items/player_item_controller.gd
core/items/inventory_model.gd
autoload/content_catalog.gd
autoload/save_manager.gd
ui/foundation_hud.gd
```

Alasannya: item di project ini sudah mempunyai jalur bersama.

```text
Input
  → PlayerItemController membaca item aktif
  → ItemDefinition memilih ItemBehavior
  → ItemBehavior mengembalikan ItemActionResult
  → controller melakukan consume, update state, atau spawn secara aman
```

Behavior item tidak boleh mengurangi inventory sendiri. Behavior cukup mengatakan hasil yang diinginkan melalui `ItemActionResult`.

Sebelum membuat file, minta atau tulis jawaban untuk checklist ini:

- `item_id` unik apa yang digunakan?
- Apa yang terjadi saat klik kiri?
- Apa yang terjadi saat klik kanan?
- Apakah item dikonsumsi?
- Apakah item dapat dilempar dan diambil kembali?
- Berapa `max_stack`?
- Apakah item menyimpan state seperti `active`, durability, atau timer?
- Target validnya player, enemy, terrain, atau interaction object?
- Apakah item dapat dijual dan berapa nilainya?
- Apakah behavior ini sudah ada pada item lain?

Jika jawaban primary/secondary belum diputuskan, jangan menebak behavior desain.

---

# 2. Mengenal GUI Godot yang akan dipakai

Saat project terbuka, fokus pada lima area berikut.

## 2.1 FileSystem dock

Biasanya berada di kiri bawah. Ini adalah tampilan folder `res://`, yaitu root repository Godot.

Gunakan FileSystem untuk:

- membuka `.tres`, `.tscn`, `.gd`, dan asset,
- mencari file melalui kotak filter,
- menduplikasi Resource,
- mengganti nama file,
- memindahkan file melalui drag-and-drop.

Jangan memindahkan file shared sembarangan. Godot dapat memperbarui beberapa reference, tetapi perpindahan file tetap mudah menimbulkan konflik Git.

## 2.2 Scene dock

Biasanya berada di kiri atas. Scene dock menampilkan tree node dari scene yang sedang dibuka.

Contoh:

```text
FoundationTestRoom
├── Player
├── RockPickup
├── TestAmphibian
└── FoundationHUD
```

Klik sebuah node untuk mengedit property node tersebut melalui Inspector.

## 2.3 Inspector dock

Biasanya berada di kanan. Inspector menampilkan semua field `@export` dari Resource, script, atau node yang sedang dipilih.

Untuk item, sebagian besar pekerjaan dilakukan di Inspector. Jangan mengedit teks `.tres` secara manual jika field dapat diubah dari Inspector.

## 2.4 Workspace 2D dan Script

Tombol **2D** dan **Script** berada di bagian atas editor.

- **2D** dipakai untuk menempatkan pickup pada test room.
- **Script** dipakai untuk menulis behavior `.gd`.

Klik tab file di bagian atas untuk berpindah antar-scene/script yang sudah dibuka.

## 2.5 Output dan Debugger

Panel ini berada di bagian bawah.

- **Output** menunjukkan log, `print`, parser error, dan `FOUNDATION_SMOKE_OK`.
- **Debugger** menunjukkan error runtime dan stack trace.

Sebelum test, bersihkan atau ingat jumlah error lama. Yang penting adalah tidak muncul error baru ketika item digunakan.

## 2.6 Tombol menjalankan game

- **F6 / Run Current Scene:** menjalankan scene yang sedang terbuka.
- **F5 / Run Project:** menjalankan game dari main menu.
- **F8 / Stop:** menghentikan game yang sedang berjalan.

Gunakan F6 untuk sandbox dan smoke test. Gunakan F5 sebelum menyatakan item selesai.

---

# 3. Membuka project dengan benar

1. Jalankan `/usr/bin/Godot` atau buka Godot melalui application menu.
2. Jika project belum muncul di Project Manager, klik **Import**.
3. Pilih file:

   ```text
   /home/slopper/CCI-GD-Project/project.godot
   ```

4. Klik **Import & Edit**.
5. Tunggu FileSystem selesai melakukan scan/import.
6. Lihat panel Output. Jangan mulai bekerja jika ada parser error baru.
7. Pastikan branch/task milikmu tidak sedang mengedit file yang sama dengan anggota lain.

Folder `.godot/` dibuat otomatis oleh editor dan tidak boleh dimasukkan ke commit.

---

# 4. Memahami file item yang sudah ada

Buka folder berikut dari FileSystem:

```text
data/items/
```

Saat ini ada dua contoh utama:

- `throwable_rock.tres` — item biasa yang memakai behavior lempar default.
- `multitool.tres` — item dengan primary behavior khusus dan secondary disabled.

Double-click `throwable_rock.tres`. Inspector akan menampilkan sebuah `ItemDefinition`.

Field pentingnya:

| Field Inspector | Arti |
| --- | --- |
| `Item Id` | ID stabil dan unik. Gunakan huruf kecil serta underscore. |
| `Display Name` | Nama yang dilihat player. |
| `Unknown Description` | Deskripsi sebelum item dikenal. |
| `Known Description` | Deskripsi setelah item dikenal. |
| `Category` | Kategori data seperti `ordinary`, `relic`, `supply`, atau `tool`. |
| `Icon` | Texture untuk UI. Boleh kosong selama placeholder. |
| `World Scene` | Reference scene item dunia. Untuk item biasa gunakan `world_item.tscn`. |
| `Max Stack` | Jumlah maksimum per slot. |
| `Purchase Price` | Harga beli. `0` berarti tidak dibeli dari stock biasa. |
| `Surface Sale Value` | Harga jual dasar di surface. |
| `Delivery Value` | Kontribusi progression ketika dijual/dikirim. |
| `Discovery Threshold` | Jumlah penggunaan untuk membuka deskripsi jika sistem discovery dipakai. |
| `Sellable` | Apakah shop boleh menjual item dari inventory player. |
| `Persistent When Dropped` | Apakah world item ikut living-run save. |
| `Retrievable` | Apakah item lempar dapat diambil kembali. |
| `Behavior` | Resource yang menjalankan primary/secondary action. Tidak boleh kosong. |

`ContentCatalog` otomatis membaca semua `.tres` di `data/items/`. Tidak perlu menambahkan item ke daftar manual.

---

# 5. Latihan pertama: membuat item lempar tanpa script baru

Ini adalah jalur termudah dan sebaiknya menjadi item pertama yang dikerjakan.

Contoh latihan menggunakan ID `practice_pebble`. Ganti dengan ID item asli ketika mengerjakan task sebenarnya. Jangan commit item latihan jika bukan bagian game.

## 5.1 Duplikasi Resource melalui FileSystem

1. Di FileSystem, buka `data/items/`.
2. Klik kanan `throwable_rock.tres`.
3. Pilih **Duplicate**.
4. Masukkan nama:

   ```text
   practice_pebble.tres
   ```

5. Double-click file baru.

Duplikasi lebih aman daripada membuat Resource kosong karena reference behavior dan world scene sudah valid.

## 5.2 Isi ItemDefinition melalui Inspector

Ubah field berikut:

```text
Item Id: practice_pebble
Display Name: Practice Pebble
Unknown Description: A small unfamiliar pebble.
Known Description: A simple recoverable throwing item.
Category: ordinary
Max Stack: 8
Sellable: Off
Persistent When Dropped: On
Retrievable: On
```

Biarkan:

```text
World Scene: world_item.tscn
Behavior: DefaultThrowBehavior
```

Klik bagian `Behavior` untuk membukanya. Karena file berasal dari rock, field berikut tersedia:

```text
Minimum Speed
Maximum Speed
Maximum Cursor Distance
Base Damage
Item Mass
```

Gunakan nilai awal yang aman:

```text
Minimum Speed: 80
Maximum Speed: 420
Maximum Cursor Distance: 240
Base Damage: 1
Item Mass: 0.5
```

Tekan **Ctrl+S**. Perhatikan tanda bintang pada tab/file; tanda tersebut harus hilang setelah tersimpan.

## 5.3 Apa yang sudah bekerja tanpa code tambahan

Dengan hanya Resource di atas:

- catalog dapat menemukan item,
- inventory dapat menyimpan dan men-stack item,
- klik kanan melempar satu unit,
- kekuatan lempar mengikuti jarak cursor,
- thrown item menghasilkan damage/force,
- item berhenti lalu dapat diambil kembali,
- state/quantity inventory dapat disimpan.

Jangan membuat script baru jika seluruh kebutuhan item sudah dipenuhi oleh `DefaultThrowBehavior`.

---

# 6. Menambahkan icon melalui GUI

Jika art team sudah memberikan PNG:

1. Pastikan nama file jelas, misalnya `practice_pebble.png`.
2. Melalui file manager OS, letakkan file di folder asset yang disepakati tim, misalnya:

   ```text
   art/items/practice_pebble.png
   ```

3. Kembali ke Godot dan tunggu asset muncul di FileSystem.
4. Pilih `.tres` item.
5. Drag PNG dari FileSystem ke field `Icon` di Inspector.
6. Tekan Ctrl+S.

Project sudah memakai nearest filtering. Jangan mengubah import setting global hanya untuk satu item.

Penting: HUD dan world scene prototype saat ini masih memakai label/polygon placeholder. Mengisi `Icon` belum tentu langsung mengganti visual hotbar atau object dunia. Itu bukan error item definition. Jangan membuat sistem UI baru dari dalam task item.

---

# 7. Membuat sandbox item melalui GUI

F3 **Give Rock** hanya memberikan `throwable_rock`; tombol tersebut tidak otomatis mengetahui item baru. Cara GUI paling aman adalah memakai copy lokal test room.

## 7.1 Buat copy lokal room

1. Di FileSystem, pilih:

   ```text
   game/world/foundation_test_room.tscn
   ```

2. Klik kanan → **Duplicate**.
3. Simpan sebagai:

   ```text
   game/world/test/local_item_sandbox.tscn
   ```

4. Double-click `local_item_sandbox.tscn`.

File ini hanya workbench lokal. Jangan masukkan ke commit kecuali lead meminta test room bersama.

## 7.2 Ganti pickup sandbox

1. Di Scene dock, klik node `RockPickup`.
2. Di Inspector cari field `Item Id`.
3. Ganti nilainya menjadi:

   ```text
   practice_pebble
   ```

4. Atur `Quantity` jika perlu.
5. Tekan Ctrl+S.

## 7.3 Jalankan sandbox

1. Tekan **F6**.
2. Dekati pickup cokelat.
3. Tekan **E**.
4. Pastikan nama item muncul pada hotbar/inventory.
5. Gunakan **1/2** atau mouse wheel untuk memilih slot.
6. Klik kanan ke arah kiri dan kanan.
7. Ambil kembali item setelah berhenti.
8. Buka inventory dengan **Tab** dan periksa quantity.
9. Tekan **F8** untuk berhenti.
10. Periksa Output dan Debugger.

Setelah selesai, hapus `local_item_sandbox.tscn` melalui FileSystem Godot atau pastikan file tidak ikut commit.

---

# 8. Kapan item membutuhkan script behavior baru

Buat script baru hanya jika behavior yang diminta tidak dapat dilakukan oleh behavior yang sudah tersedia.

Contoh kebutuhan script baru:

- klik kiri mengeluarkan sound event,
- klik kiri memberi status melalui `apply_status`,
- item mencari interaction target khusus,
- item membuat world effect,
- secondary tidak boleh melempar,
- item mengubah instance state.

Sebelum menulis code, baca:

```text
game/items/behaviors/default_throw_behavior.gd
game/items/behaviors/multitool_behavior.gd
```

Gunakan script yang paling mirip sebagai contoh.

---

# 9. Membuat behavior baru melalui GUI Script editor

Contoh berikut membuat item yang mengirim sound saat klik kiri dan tetap memakai lemparan default saat klik kanan.

## 9.1 Buat script

1. Di FileSystem, buka `game/items/behaviors/`.
2. Klik kanan folder → **Create New** → **Script**.
3. Nama file:

   ```text
   noise_lure_behavior.gd
   ```

4. Pastikan bahasa **GDScript**.
5. Klik **Create**.
6. Godot akan membuka workspace Script.

Jika menu pembuatan script tidak tersedia dari klik kanan, buka workspace **Script**, pilih menu **File → New Script**, lalu simpan ke path di atas.

## 9.2 Isi script minimum

Ganti isi script dengan:

```gdscript
class_name NoiseLureBehavior
extends DefaultThrowBehavior

@export var sound_radius := 180.0
@export var sound_priority := 1

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.world != null

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if not can_primary(context, state):
		return ItemActionResult.failed("Cannot make sound here")
	SoundBus.emit_sound(
		context.world.get_tree(),
		SoundEvent.new(
			context.actor.global_position,
			sound_radius,
			&"item_lure",
			sound_priority,
			context.actor
		)
	)
	var result := ItemActionResult.completed(0, state)
	result.message = "Sound emitted"
	return result
```

Tekan Ctrl+S.

Mengapa script ini aman:

- `extends DefaultThrowBehavior` menggunakan secondary throw yang sudah diuji,
- primary memvalidasi context,
- tidak membuka atau mengubah array inventory,
- `completed(0, state)` berarti tidak mengonsumsi item dan mempertahankan state,
- nilai radius/priority dapat diubah dari Inspector,
- emitter memakai `SoundBus` bersama dan tidak mencari frog secara langsung.

Jangan menulis `get_node("/root/.../Frog")` atau memeriksa nama scene enemy.

## 9.3 Pasang behavior ke ItemDefinition

1. Kembali ke file `.tres` item melalui FileSystem.
2. Di Inspector cari `Behavior`.
3. Klik dropdown kecil di sebelah field tersebut.
4. Pilih **New NoiseLureBehavior**.
5. Expand Resource behavior.
6. Isi:

   ```text
   Sound Radius: 180
   Sound Priority: 1
   Minimum Speed: 80
   Maximum Speed: 420
   Maximum Cursor Distance: 240
   Base Damage: 0
   Item Mass: 0.5
   ```

7. Tekan Ctrl+S.

Jika `New NoiseLureBehavior` tidak muncul:

1. buka script,
2. lihat apakah ada baris merah/parser error,
3. periksa Output,
4. simpan script,
5. tunggu beberapa detik agar global class diperbarui,
6. jika perlu tutup dan buka kembali `.tres`.

---

# 10. Pola ItemActionResult yang wajib dipahami

## 10.1 Action gagal

```gdscript
return ItemActionResult.failed("Target tidak valid")
```

Hasil gagal tidak boleh mengonsumsi item.

## 10.2 Action berhasil tanpa consume

```gdscript
var result := ItemActionResult.completed(0, state)
result.message = "Item digunakan"
return result
```

## 10.3 Action berhasil dan mengonsumsi satu

```gdscript
var result := ItemActionResult.completed(1)
result.message = "Item dikonsumsi"
return result
```

Jangan memanggil `inventory.remove_active()` dari behavior.

## 10.4 Action mengubah state item

```gdscript
var next_state := state.duplicate(true)
next_state["active"] = true
var result := ItemActionResult.completed(0, next_state)
result.message = "Item diaktifkan"
return result
```

Untuk prototype sekarang, set `Max Stack = 1` pada item stateful. Sistem pemisahan satu unit aktif dari stack belum lengkap untuk semua behavior, sehingga stack stateful quantity besar berisiko mengubah state seluruh stack.

## 10.5 Membuat world node

Behavior boleh membuat node lalu menaruhnya pada result:

```gdscript
var result := ItemActionResult.completed(1)
result.world_node = effect_scene.instantiate()
return result
```

Jangan `context.world.add_child()` lalu mengurangi inventory sendiri. Controller harus melakukan commit agar spawn gagal tidak menghilangkan item.

---

# 11. Contoh consumable primary sederhana

Jika item memberi status yang sudah terdaftar, behavior minimum dapat menggunakan contract player `apply_status`.

```gdscript
class_name SimpleStatusItemBehavior
extends ItemBehavior

@export var effect_id: StringName

func can_primary(context: ItemContext, _state: Dictionary) -> bool:
	return context.actor != null and context.actor.has_method("apply_status")

func primary(context: ItemContext, state: Dictionary) -> ItemActionResult:
	if not can_primary(context, state):
		return ItemActionResult.failed("Cannot use item")
	if not context.actor.apply_status(effect_id):
		return ItemActionResult.failed("Effect unavailable")
	var result := ItemActionResult.completed(1)
	result.message = "Effect applied"
	return result
```

Behavior ini tidak mempunyai secondary action karena langsung `extends ItemBehavior`. Jangan otomatis menambah throw untuk supply jika desain secondary belum diputuskan.

Gunakan effect ID yang benar-benar ada di `data/effects/`. Jangan mengetik ID fiktif lalu menganggap item selesai.

---

# 12. State runtime: jangan disimpan pada Resource behavior

Ini salah:

```gdscript
var active := false
var remaining_time := 5.0
```

Jika field tersebut berada pada `ItemBehavior` Resource, beberapa instance item dapat berbagi data yang sama.

Simpan data per-item di:

- `state`/`next_state` untuk state inventory instance,
- node world yang dibuat item untuk timer/effect runtime,
- `ThrownItem.instance_state` untuk state yang ikut dilempar.

Item bertimer seperti Rattlepod membutuhkan owner node runtime yang melakukan `_process`/timer. Jangan menaruh timer berjalan pada shared behavior Resource.

`ThrownItem.on_impact()` saat ini cocok untuk effect impact sederhana, tetapi result dari hook tersebut belum melakukan consume/state commit kedua. Jika item membutuhkan lifecycle kompleks, berhenti dan diskusikan contract dengan lead sebelum mengubah `ThrownItem`.

---

# 13. Menambahkan assertion catalog minimum

Setiap item baru minimal harus terbukti terdaftar.

1. Di FileSystem buka:

   ```text
   tests/foundation_smoke.gd
   ```

2. Cari function:

   ```gdscript
   func _test_catalog() -> void:
   ```

3. Tambahkan assertion menggunakan ID item:

   ```gdscript
   assert(ContentCatalog.get_item(&"practice_pebble") != null)
   ```

4. Simpan script.
5. Buka `tests/foundation_smoke.tscn` melalui FileSystem.
6. Tekan F6.
7. Scene akan menutup sendiri.
8. Output harus berisi:

   ```text
   FOUNDATION_SMOKE_OK
   ```

Jika behavior mempunyai logic non-trivial, assertion catalog saja belum cukup. Tambahkan satu test kecil yang membuktikan hasil utama atau minta pairing dengan programmer yang memahami smoke runner.

Jangan membuat framework test baru.

---

# 14. Acceptance test manual melalui GUI

Jalankan seluruh daftar yang relevan:

## Data dan catalog

- Item muncul tanpa startup error.
- `item_id` tidak kosong dan tidak duplicate.
- Nama/deskripsi benar.
- Behavior tidak kosong.
- Angka tuning dapat diedit dari Inspector.

## Inventory

- Pickup masuk hotbar kosong lalu backpack.
- Stack berhenti pada `Max Stack`.
- Inventory penuh menolak pickup tanpa menghapus world item.
- Swap hotbar/backpack tidak menduplikasi item.

## Primary

- Klik kiri pada context valid berhasil.
- Context tidak valid memberi feedback dan tidak mengonsumsi item.
- Consume quantity tepat.
- Effect tidak diterapkan dua kali dari satu klik.

## Secondary

- Klik kanan sesuai desain: throw, custom action, atau feedback unavailable.
- Throw bekerja ke kiri dan kanan.
- Cursor dekat menghasilkan throw pendek.
- Quantity berkurang satu setelah spawn berhasil.

## World dan persistence

- Retrievable item dapat diambil kembali setelah berhenti.
- Item yang berasal dari player tidak duplicate setelah save/Continue.
- Item consumable benar-benar hilang setelah digunakan.
- Death/New Run mengikuti aturan item.

## Error

- Output tidak menampilkan parser error.
- Debugger tidak menambah error saat primary/secondary digunakan berulang.
- F5 dari main menu tetap dapat menjalankan game.
- `FOUNDATION_SMOKE_OK` tetap muncul.

---

# 15. Error umum dan cara memperbaikinya melalui GUI

## “Item tidak ditemukan” atau pickup menampilkan ID mentah

Periksa:

1. `.tres` berada di `data/items/`.
2. `Item Id` sudah diisi.
3. Resource sudah disimpan.
4. Tidak ada duplicate ID.
5. Stop game lalu jalankan ulang agar catalog rebuild.
6. Lihat Output untuk path Resource yang gagal.

## “Behavior is missing”

Pilih `.tres`, cari field `Behavior`, lalu assign behavior yang sesuai. ItemDefinition tanpa behavior dianggap invalid.

## Custom behavior tidak muncul di dropdown

Periksa `class_name`, `extends`, dan parser error pada script. Godot hanya menampilkan global Resource class yang berhasil di-parse.

## Klik kiri selalu “Action unavailable”

`can_primary()` mengembalikan false atau behavior tidak mengimplementasikan primary. Pasang breakpoint di gutter kiri Script editor atau tambahkan `print` sementara, lalu lihat Output.

Hapus `print` debugging yang spam sebelum commit.

## Klik kanan tidak melempar

Pastikan behavior `extends DefaultThrowBehavior` atau mengimplementasikan `can_secondary()` dan `secondary()` sendiri.

## Item aktif mengubah seluruh stack

Set `Max Stack = 1` untuk item stateful. Jangan memperbaiki inventory splitting dari task item tanpa koordinasi.

## Icon sudah dipasang tetapi HUD/world tetap placeholder

Data icon sudah benar; prototype UI/world visual belum membaca semua asset item. Laporkan sebagai integration task terpisah, bukan behavior bug.

## Error lama masih terlihat di Debugger

Clear Debugger, jalankan ulang satu test, lalu lihat error yang timestamp-nya baru. Jangan menganggap seluruh history berasal dari itemmu.

---

# 16. Checklist sebelum menyerahkan item

Pastikan perubahan final hanya mencakup file yang memang diperlukan:

```text
[ ] data/items/<id>.tres
[ ] game/items/behaviors/<id>_behavior.gd jika diperlukan
[ ] asset item yang benar-benar digunakan
[ ] assertion/test minimum
```

Pastikan tidak ikut terbawa:

```text
[ ] .godot/
[ ] builds/
[ ] log
[ ] local_item_sandbox.tscn
[ ] perubahan project.godot dari editor
[ ] perubahan scene/menu milik anggota lain
```

Laporan handoff kepada lead sebaiknya berisi:

```text
Item ID:
Primary:
Secondary:
Consume/state:
File yang berubah:
Test manual yang lulus:
Smoke result:
Hal yang masih TBD:
```

Satu item belum selesai hanya karena `.tres` dapat dibuka. Item selesai ketika dapat diperoleh, digunakan, mengikuti quantity/state yang benar, tidak menambah debugger error, dan lulus smoke test.

---

# 17. Urutan kerja yang disarankan untuk item game asli

Kerjakan dari paling sederhana:

1. **Throwable/data-only item** — duplicate rock dan tuning Resource.
2. **Instant consumable** — satu primary action, consume satu, secondary sesuai keputusan desain.
3. **Simple reusable artifact** — primary effect melalui shared API, secondary inherited throw.
4. **Stateful item** — `max_stack = 1`, state melalui `next_state`.
5. **World-lifecycle item** — timer, deployed node, impact, persistence; lakukan setelah contractnya disetujui.

Jika item baru membutuhkan perubahan pada Player, Inventory, SaveManager, ContentCatalog, atau generic ThrownItem, hentikan dahulu. Tulis kebutuhan yang tidak dapat dipenuhi contract sekarang dan minta review fondasi. Jangan menyelundupkan perubahan sistem besar ke commit satu item.
