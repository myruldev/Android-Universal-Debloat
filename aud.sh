#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  ANDROID UNIVERSAL DEBLOAT  -  untuk Termux + Shizuku (rish)
#  Tanpa ROOT. Aman, bisa dibatalkan (restore).
#  Bahasa: Indonesia (ramah pengguna awam)
# ------------------------------------------------------------
#  Author  : myrul.dev
#  Website : https://www.myrul.dev
#  Facebook: https://web.facebook.com/myruldev
#  License : MIT
# ============================================================

# ----- Lokasi folder kerja (mengikuti lokasi script) --------
DIR="$(cd "$(dirname "$0")" && pwd)"
DB_DIR="$DIR/database"
BACKUP_DIR="$DIR/backup"
LOG_DIR="$DIR/logs"
LOG_FILE="$LOG_DIR/actions.log"

mkdir -p "$DB_DIR" "$BACKUP_DIR" "$LOG_DIR"
touch "$LOG_FILE"

# ----- Warna terminal --------------------------------------
C_RESET="\033[0m"
C_HIJAU="\033[1;32m"
C_KUNING="\033[1;33m"
C_MERAH="\033[1;31m"
C_BIRU="\033[1;36m"
C_ABU="\033[0;37m"

# ----- USER ID (default 0 = pengguna utama) ----------------
USER_ID=0

# ----- Mode simulasi: 1 = hanya pura-pura (tidak eksekusi) -
DRY_RUN=0

# ============================================================
#  WHITELIST: paket penting yang TIDAK BOLEH disentuh
# ============================================================
WHITELIST=(
  "com.android.systemui"
  "com.android.settings"
  "com.google.android.gms"
  "com.google.android.gsf"
  "com.android.vending"
  "com.android.permissioncontroller"
  "com.android.packageinstaller"
  "com.android.providers.downloads"
  "com.android.providers.media"
)

# Muat whitelist tambahan buatan pengguna (database/whitelist.txt)
muat_whitelist_kustom() {
  local f="$DB_DIR/whitelist.txt"
  [ -f "$f" ] || return 0
  local line
  while IFS= read -r line; do
    line="$(echo "$line" | tr -d ' \r\t')"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    WHITELIST+=("$line")
  done < "$f"
}
muat_whitelist_kustom

# ============================================================
#  FUNGSI BANTUAN
# ============================================================

# Tulis ke log
log_aksi() {
  local pesan="$1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $pesan" >> "$LOG_FILE"
}

check_update() {
  # Cek apakah folder ini git repo
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    return 0
  fi

  # Cek koneksi internet ke github (timeout 2 detik)
  if ! ping -c 1 -W 2 github.com >/dev/null 2>&1; then
    # Jika ping gagal, coba fetch dengan timeout config
    if ! git -c network.http.connectionTimeout=2 fetch origin >/dev/null 2>&1; then
      return 0
    fi
  else
    git fetch origin >/dev/null 2>&1 || return 0
  fi

  local_sha="$(git rev-parse HEAD 2>/dev/null)"
  remote_sha="$(git rev-parse @{u} 2>/dev/null)"

  if [ -n "$local_sha" ] && [ -n "$remote_sha" ] && [ "$local_sha" != "$remote_sha" ]; then
    echo
    echo -e "${C_KUNING}┌──────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_KUNING}│         PEMBARUAN TERSEDIA DI GITHUB!        │${C_RESET}"
    echo -e "${C_KUNING}├──────────────────────────────────────────────┤${C_RESET}"
    echo -e "${C_KUNING}│  Ada versi baru yang tersedia untuk diunduh.  │${C_RESET}"
    echo -e "${C_KUNING}└──────────────────────────────────────────────┘${C_RESET}"
    echo
    read -r -p "Update otomatis sekarang? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      echo "Mengunduh pembaruan..."
      if git pull origin main >/dev/null 2>&1 || git pull >/dev/null 2>&1; then
        echo -e "${C_HIJAU}Update sukses! Memulai ulang script...${C_RESET}"
        sleep 1
        exec bash "$0" "$@"
      else
        echo -e "${C_MERAH}Gagal melakukan git pull. Silakan update manual.${C_RESET}"
        sleep 2
      fi
    fi
  fi
}

garis() {
  echo -e "${C_ABU}------------------------------${C_RESET}"
}

# ----- Kecepatan animasi (detik per huruf) -----------------
SPEED=0.006

# Animasi ketik (teks muncul satu-satu)
ketik() {
  local teks="$1"; local d="${2:-$SPEED}"
  local i
  for ((i=0; i<${#teks}; i++)); do
    printf "%s" "${teks:$i:1}"
    sleep "$d" 2>/dev/null
  done
  echo
}

# Animasi loading (spinner singkat)
loading() {
  local teks="${1:-Memuat}"
  local spin='|/-\'
  local n=0
  while [ "$n" -lt 14 ]; do
    printf "\r${C_KUNING}%s %s...${C_RESET}" "${spin:$((n%4)):1}" "$teks"
    sleep 0.07 2>/dev/null
    n=$((n+1))
  done
  printf "\r${C_HIJAU}> %s... oke${C_RESET}   \n" "$teks"
}

judul() {
  clear
  echo -e "${C_BIRU}"
  echo "  ┌──────────────────────────────────────────────┐"
  echo "  │            █████╗ ██╗   ██╗██████╗           │"
  echo "  │          ██╔══██╗██║   ██║██╔══██╗           │"
  echo "  │          ███████║██║   ██║██║  ██║           │"
  echo "  │          ██╔══██║██║   ██║██║  ██║           │"
  echo "  │          ██║  ██║╚██████╔╝██████╔╝           │"
  echo "  │          ╚═╝  ╚═╝ ╚═════╝ ╚═════╝            │"
  echo -e "  │         ${C_HIJAU}Android Universal Debloat v1${C_BIRU}         │"
  echo -e "  │    ${C_ABU}Bersihkan bloatware Android tanpa root${C_BIRU}    │"
  echo -e "  │     ${C_ABU}------------------------------------${C_BIRU}     │"
  echo -e "  │  ${C_ABU}Website : ${C_BIRU}www.myrul.dev${C_BIRU}                     │"
  echo -e "  │  ${C_ABU}Facebook: ${C_BIRU}https://web.facebook.com/myruldev${C_BIRU} │"
  echo "  └──────────────────────────────────────────────┘"
  echo -e "${C_RESET}"
}

tekan_enter() {
  echo
  echo -ne "${C_ABU}Tekan ENTER buat balik...${C_RESET}"
  read -r _
}

# Konfirmasi y/n -> return 0 kalau "y"
konfirmasi() {
  local pesan="${1:-Yakin lanjut?}"
  local jawab
  echo
  echo -ne "${C_KUNING}${pesan} (y/n): ${C_RESET}"
  read -r jawab
  case "$jawab" in
    y|Y|ya|YA|Ya) return 0 ;;
    *) return 1 ;;
  esac
}

# Cek apakah paket ada di whitelist
ada_di_whitelist() {
  local pkg="$1"
  for w in "${WHITELIST[@]}"; do
    [ "$w" = "$pkg" ] && return 0
  done
  return 1
}

# Jalankan perintah lewat rish
rish_run() {
  rish -c "$1"
}

# ============================================================
#  1. CEK DEPENDENCY (Termux, rish, Shizuku)
# ============================================================
cek_dependency() {
  judul
  echo -e "${C_BIRU}Langkah 1: Memeriksa perlengkapan yang dibutuhkan${C_RESET}"
  garis
  local gagal=0

  # Termux
  if [ -d "/data/data/com.termux" ] || [ -n "$PREFIX" ]; then
    echo -e "  ${C_HIJAU}[OK]${C_RESET}  Termux terpasang"
  else
    echo -e "  ${C_KUNING}[?]${C_RESET}   Tidak terdeteksi sebagai Termux (lanjut saja jika yakin)"
  fi

  # rish tersedia
  if command -v rish >/dev/null 2>&1; then
    echo -e "  ${C_HIJAU}[OK]${C_RESET}  Perintah 'rish' tersedia"
  else
    echo -e "  ${C_MERAH}[X]${C_RESET}   'rish' tidak ditemukan."
    echo -e "       Pastikan kamu sudah menyiapkan rish dari aplikasi Shizuku."
    gagal=1
  fi

  # Shizuku aktif (uji jalankan perintah ringan)
  if command -v rish >/dev/null 2>&1; then
    if rish_run "echo SHIZUKU_OK" 2>/dev/null | grep -q "SHIZUKU_OK"; then
      echo -e "  ${C_HIJAU}[OK]${C_RESET}  Shizuku aktif dan dapat menjalankan perintah"
    else
      echo -e "  ${C_MERAH}[X]${C_RESET}   Shizuku belum aktif / belum diberi izin."
      echo -e "       Buka aplikasi Shizuku, nyalakan service, lalu coba lagi."
      gagal=1
    fi
  fi

  garis
  if [ "$gagal" -eq 0 ]; then
    echo -e "${C_HIJAU}Semua perlengkapan siap digunakan.${C_RESET}"
    return 0
  else
    echo -e "${C_MERAH}Ada perlengkapan yang belum siap. Perbaiki dulu ya.${C_RESET}"
    return 1
  fi
}

# ============================================================
#  2. DETEKSI DEVICE (getprop lewat rish)
# ============================================================
ambil_prop() {
  rish_run "getprop $1" 2>/dev/null | tr -d '\r'
}

deteksi_device() {
  BRAND="$(ambil_prop ro.product.brand)"
  MANUFACTURER="$(ambil_prop ro.product.manufacturer)"
  MODEL="$(ambil_prop ro.product.model)"
  ANDROID_VER="$(ambil_prop ro.build.version.release)"

  [ -z "$BRAND" ] && BRAND="tidak diketahui"
  [ -z "$MANUFACTURER" ] && MANUFACTURER="tidak diketahui"
  [ -z "$MODEL" ] && MODEL="tidak diketahui"
  [ -z "$ANDROID_VER" ] && ANDROID_VER="tidak diketahui"
}

tampil_device() {
  deteksi_device
  echo -e "${C_BIRU}Informasi HP kamu:${C_RESET}"
  echo -e "  Merek (brand)     : ${C_HIJAU}${BRAND}${C_RESET}"
  echo -e "  Pabrikan          : ${C_HIJAU}${MANUFACTURER}${C_RESET}"
  echo -e "  Tipe (model)      : ${C_HIJAU}${MODEL}${C_RESET}"
  echo -e "  Versi Android     : ${C_HIJAU}${ANDROID_VER}${C_RESET}"
}

# Pilih file database brand sesuai HP (selain universal)
pilih_database_brand() {
  local b
  b="$(echo "$BRAND $MANUFACTURER" | tr '[:upper:]' '[:lower:]')"
  case "$b" in
    *xiaomi*|*redmi*|*poco*)        echo "$DB_DIR/xiaomi.txt" ;;
    *samsung*)                      echo "$DB_DIR/samsung.txt" ;;
    *oppo*)                         echo "$DB_DIR/oppo.txt" ;;
    *vivo*|*iqoo*)                  echo "$DB_DIR/vivo.txt" ;;
    *realme*)                       echo "$DB_DIR/realme.txt" ;;
    *infinix*)                      echo "$DB_DIR/infinix.txt" ;;
    *tecno*)                        echo "$DB_DIR/tecno.txt" ;;
    *itel*)                         echo "$DB_DIR/itel.txt" ;;
    *oneplus*)                      echo "$DB_DIR/oneplus.txt" ;;
    *honor*)                        echo "$DB_DIR/honor.txt" ;;
    *huawei*)                       echo "$DB_DIR/huawei.txt" ;;
    *motorola*|*moto*|*lenovo-moto*) echo "$DB_DIR/motorola.txt" ;;
    *asus*)                         echo "$DB_DIR/asus.txt" ;;
    *sony*|*xperia*)                echo "$DB_DIR/sony.txt" ;;
    *nokia*|*hmd*)                  echo "$DB_DIR/nokia.txt" ;;
    *google*|*pixel*)               echo "$DB_DIR/pixel.txt" ;;
    *zte*)                          echo "$DB_DIR/zte.txt" ;;
    *nubia*|*redmagic*|*"red magic"*) echo "$DB_DIR/nubia.txt" ;;
    *lenovo*)                       echo "$DB_DIR/lenovo.txt" ;;
    *meizu*)                        echo "$DB_DIR/meizu.txt" ;;
    *lge*|*"lg electronics"*)       echo "$DB_DIR/lg.txt" ;;
    *tcl*|*alcatel*)                echo "$DB_DIR/tcl.txt" ;;
    *wiko*)                         echo "$DB_DIR/wiko.txt" ;;
    *sharp*|*aquos*)                echo "$DB_DIR/sharp.txt" ;;
    *)                              echo "" ;;
  esac
}

# ============================================================
#  3. SCAN SEMUA PACKAGE (pm list packages)
# ============================================================
scan_paket_terpasang() {
  # Hasil: daftar nama paket (tanpa awalan "package:")
  rish_run "pm list packages" 2>/dev/null | sed 's/^package://' | tr -d '\r' | sort
}

paket_terpasang() {
  # cek apakah satu paket terpasang
  local pkg="$1"
  rish_run "pm list packages $pkg" 2>/dev/null | tr -d '\r' | grep -q "package:$pkg$"
}

menu_scan_hp() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  tampil_device
  garis
  loading "Ngitung aplikasi"
  local daftar jumlah
  daftar="$(scan_paket_terpasang)"
  jumlah="$(echo "$daftar" | grep -c .)"
  echo -e "  Total aplikasi terpasang: ${C_HIJAU}${jumlah}${C_RESET}"
  garis

  local db_brand
  db_brand="$(pilih_database_brand)"
  echo -e "${C_BIRU}Database yang dipakai:${C_RESET}"
  echo -e "  - universal.txt (untuk semua HP)"
  if [ -n "$db_brand" ] && [ -f "$db_brand" ]; then
    echo -e "  - $(basename "$db_brand") (khusus merek HP kamu)"
  else
    echo -e "  - (tidak ada database khusus untuk merek HP ini)"
  fi

  garis
  echo -e "${C_BIRU}Aplikasi bawaan yang dikenali dan masih terpasang:${C_RESET}"
  echo
  printf "  %-45s %-22s %s\n" "PAKET" "NAMA" "RISIKO"
  garis
  local total_kenal=0
  while IFS='|' read -r pkg nama risk; do
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    if echo "$daftar" | grep -qx "$pkg"; then
      printf "  %-45s %-22s %s\n" "$pkg" "$nama" "$risk"
      total_kenal=$((total_kenal+1))
    fi
  done < <(baca_semua_database)
  garis
  echo -e "  Dikenali & terpasang: ${C_HIJAU}${total_kenal}${C_RESET} aplikasi"
  log_aksi "SCAN HP: $jumlah paket terpasang, $total_kenal dikenali database"
  tekan_enter
}

# ============================================================
#  DATABASE: gabungkan universal + brand
#  Format baris: package|nama aplikasi|risk
# ============================================================
baca_satu_database() {
  local file="$1"
  [ -f "$file" ] || return 0
  # buang baris kosong & komentar (#)
  grep -v '^[[:space:]]*$' "$file" | grep -v '^[[:space:]]*#'
}

baca_semua_database() {
  baca_satu_database "$DB_DIR/universal.txt"
  local db_brand
  db_brand="$(pilih_database_brand)"
  [ -n "$db_brand" ] && baca_satu_database "$db_brand"
}

# Ambil daftar paket berdasarkan level risiko yang diizinkan
# Argumen: daftar risiko yang boleh (mis: "safe" atau "safe recommended")
filter_database_by_risk() {
  local izin="$1"
  while IFS='|' read -r pkg nama risk; do
    pkg="$(echo "$pkg" | tr -d ' \r')"
    risk="$(echo "$risk" | tr -d ' \r' | tr '[:upper:]' '[:lower:]')"
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    for r in $izin; do
      if [ "$risk" = "$r" ]; then
        echo "$pkg|$nama|$risk"
        break
      fi
    done
  done < <(baca_semua_database)
}

# ============================================================
#  BACKUP daftar paket sebelum aksi
# ============================================================
buat_backup() {
  deteksi_device
  local stamp file
  stamp="$(date '+%Y%m%d-%H%M%S')"
  file="$BACKUP_DIR/backup-$stamp.txt"
  {
    echo "# Backup daftar paket - $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Brand: $BRAND | Model: $MODEL | Android: $ANDROID_VER"
    echo "# ----------------------------------------------------"
    scan_paket_terpasang
  } > "$file"
  echo "$file"
}

# ============================================================
#  EKSEKUSI: disable & enable satu paket
# ============================================================
disable_paket() {
  local pkg="$1"
  if ada_di_whitelist "$pkg"; then
    echo -e "  ${C_KUNING}[LEWATI]${C_RESET} $pkg (paket penting, dilindungi)"
    log_aksi "LEWATI (whitelist): $pkg"
    return 1
  fi
  if ! paket_terpasang "$pkg"; then
    echo -e "  ${C_ABU}[-]${C_RESET}      $pkg (tidak terpasang)"
    return 1
  fi
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${C_KUNING}[SIMULASI]${C_RESET} $pkg akan dinonaktifkan (tidak dieksekusi)"
    log_aksi "SIMULASI DISABLE: $pkg"
    return 0
  fi
  local out
  out="$(rish_run "pm disable-user --user $USER_ID $pkg" 2>&1)"
  if echo "$out" | grep -qi "new state\|disabled"; then
    echo -e "  ${C_HIJAU}[NONAKTIF]${C_RESET} $pkg"
    log_aksi "DISABLE: $pkg -> OK"
    return 0
  else
    echo -e "  ${C_MERAH}[GAGAL]${C_RESET}  $pkg ($out)"
    log_aksi "DISABLE: $pkg -> GAGAL ($out)"
    return 1
  fi
}

enable_paket() {
  local pkg="$1"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo -e "  ${C_KUNING}[SIMULASI]${C_RESET} $pkg akan diaktifkan (tidak dieksekusi)"
    log_aksi "SIMULASI ENABLE: $pkg"
    return 0
  fi
  local out
  out="$(rish_run "pm enable $pkg" 2>&1)"
  if echo "$out" | grep -qi "new state\|enabled"; then
    echo -e "  ${C_HIJAU}[AKTIF]${C_RESET}  $pkg"
    log_aksi "ENABLE: $pkg -> OK"
    return 0
  else
    echo -e "  ${C_MERAH}[GAGAL]${C_RESET} $pkg ($out)"
    log_aksi "ENABLE: $pkg -> GAGAL ($out)"
    return 1
  fi
}

# ============================================================
#  PROSES DEBLOAT BERDASARKAN RISIKO
# ============================================================
proses_debloat() {
  local izin="$1"        # "safe" atau "safe recommended"
  local judul_mode="$2"  # teks tampilan

  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  deteksi_device
  echo -e "${C_BIRU}Mode: ${judul_mode}${C_RESET}"
  garis

  # Kumpulkan kandidat yang terpasang
  local daftar_terpasang kandidat=()
  daftar_terpasang="$(scan_paket_terpasang)"
  while IFS='|' read -r pkg nama risk; do
    [ -z "$pkg" ] && continue
    ada_di_whitelist "$pkg" && continue
    if echo "$daftar_terpasang" | grep -qx "$pkg"; then
      kandidat+=("$pkg|$nama|$risk")
    fi
  done < <(filter_database_by_risk "$izin")

  if [ "${#kandidat[@]}" -eq 0 ]; then
    echo -e "${C_KUNING}Tidak ada aplikasi yang cocok untuk dinonaktifkan.${C_RESET}"
    tekan_enter
    return
  fi

  echo -e "${C_BIRU}Aplikasi yang akan dinonaktifkan (${#kandidat[@]} aplikasi):${C_RESET}"
  echo
  for item in "${kandidat[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    printf "  - %-22s ${C_ABU}(%s, %s)${C_RESET}\n" "$nama" "$pkg" "$risk"
  done
  garis
  echo -e "${C_KUNING}Catatan: Aplikasi hanya DINONAKTIFKAN, bukan dihapus.${C_RESET}"
  echo -e "${C_KUNING}Kamu bisa mengembalikannya lewat menu 'Pulihkan Aplikasi'.${C_RESET}"

  if ! konfirmasi "Yakin lanjut?"; then
    echo -e "${C_ABU}Dibatalkan. Tidak ada yang diubah.${C_RESET}"
    tekan_enter
    return
  fi

  echo
  echo -e "${C_BIRU}Bikin backup dulu ya...${C_RESET}"
  local bk
  bk="$(buat_backup)"
  echo -e "  Backup tersimpan: ${C_HIJAU}$bk${C_RESET}"
  log_aksi "BACKUP dibuat: $bk (mode: $judul_mode)"

  echo
  loading "Memproses"
  local sukses=0
  for item in "${kandidat[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    disable_paket "$pkg" && sukses=$((sukses+1))
  done
  garis
  echo -e "${C_HIJAU}Selesai. $sukses aplikasi berhasil dinonaktifkan.${C_RESET}"
  log_aksi "MODE $judul_mode selesai: $sukses dinonaktifkan"
  tekan_enter
}

menu_safe_debloat() {
  proses_debloat "safe" "Debloat Aman (hanya risiko: safe)"
}

menu_recommended_debloat() {
  proses_debloat "safe recommended" "Debloat Disarankan (risiko: safe + recommended)"
}

# ============================================================
#  MANUAL DEBLOAT (pilih sendiri)
# ============================================================
menu_manual_debloat() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  deteksi_device
  echo -e "${C_BIRU}Mode: Pilih Sendiri (Manual)${C_RESET}"
  garis

  local daftar_terpasang kandidat=()
  daftar_terpasang="$(scan_paket_terpasang)"
  while IFS='|' read -r pkg nama risk; do
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    pkg="$(echo "$pkg" | tr -d ' \r')"
    ada_di_whitelist "$pkg" && continue
    if echo "$daftar_terpasang" | grep -qx "$pkg"; then
      kandidat+=("$pkg|$nama|$risk")
    fi
  done < <(baca_semua_database)

  if [ "${#kandidat[@]}" -eq 0 ]; then
    echo -e "${C_KUNING}Tidak ada aplikasi bawaan yang dikenali untuk dipilih.${C_RESET}"
    tekan_enter
    return
  fi

  echo -e "${C_BIRU}Daftar aplikasi (ketik nomor yang ingin dinonaktifkan):${C_RESET}"
  echo -e "${C_ABU}Pisahkan dengan spasi. Contoh: 1 3 5${C_RESET}"
  echo
  local i=1
  for item in "${kandidat[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    printf "  %2d) %-22s ${C_ABU}(%s, %s)${C_RESET}\n" "$i" "$nama" "$pkg" "$risk"
    i=$((i+1))
  done
  garis
  echo -ne "${C_KUNING}Nomor pilihan (kosongkan untuk batal): ${C_RESET}"
  read -r pilihan
  [ -z "$pilihan" ] && { echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; }

  local terpilih=()
  for n in $pilihan; do
    case "$n" in
      ''|*[!0-9]*) continue ;;
    esac
    if [ "$n" -ge 1 ] && [ "$n" -le "${#kandidat[@]}" ]; then
      terpilih+=("${kandidat[$((n-1))]}")
    fi
  done

  if [ "${#terpilih[@]}" -eq 0 ]; then
    echo -e "${C_ABU}Tidak ada pilihan yang valid. Dibatalkan.${C_RESET}"
    tekan_enter
    return
  fi

  echo
  echo -e "${C_BIRU}Akan dinonaktifkan:${C_RESET}"
  for item in "${terpilih[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    printf "  - %-22s ${C_ABU}(%s, %s)${C_RESET}\n" "$nama" "$pkg" "$risk"
  done

  if ! konfirmasi "Yakin lanjut?"; then
    echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return
  fi

  local bk
  bk="$(buat_backup)"
  echo -e "  Cadangan disimpan: ${C_HIJAU}$bk${C_RESET}"
  log_aksi "BACKUP (manual): $bk"

  echo
  local sukses=0
  for item in "${terpilih[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    disable_paket "$pkg" && sukses=$((sukses+1))
  done
  garis
  echo -e "${C_HIJAU}Selesai. $sukses aplikasi dinonaktifkan.${C_RESET}"
  log_aksi "MANUAL selesai: $sukses dinonaktifkan"
  tekan_enter
}

# ============================================================
#  RESTORE / PULIHKAN PAKET
# ============================================================
menu_restore() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  echo -e "${C_BIRU}Pulihkan Aplikasi (aktifkan kembali)${C_RESET}"
  garis
  echo "  1) Aktifkan kembali SEMUA aplikasi yang dikenali"
  echo "  2) Aktifkan kembali satu aplikasi (ketik nama paket)"
  echo "  3) Pulihkan dari file cadangan"
  echo "  0) Kembali"
  echo
  echo -ne "${C_KUNING}Pilih (0-3): ${C_RESET}"
  read -r pil

  case "$pil" in
    1)
      echo
      echo -e "${C_BIRU}Aplikasi yang akan diaktifkan kembali:${C_RESET}"
      local pkgs=()
      while IFS='|' read -r pkg nama risk; do
        pkg="$(echo "$pkg" | tr -d ' \r')"
        [ -z "$pkg" ] && continue
        case "$pkg" in \#*) continue ;; esac
        echo -e "  - $nama ($pkg)"
        pkgs+=("$pkg")
      done < <(baca_semua_database)
      if ! konfirmasi "Yakin lanjut?"; then echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; fi
      echo
      local sukses=0
      for p in "${pkgs[@]}"; do enable_paket "$p" && sukses=$((sukses+1)); done
      garis
      echo -e "${C_HIJAU}Selesai. $sukses aplikasi diaktifkan kembali.${C_RESET}"
      log_aksi "RESTORE semua: $sukses diaktifkan"
      ;;
    2)
      echo
      echo -ne "${C_KUNING}Ketik nama paket (mis: com.contoh.app): ${C_RESET}"
      read -r pkg
      pkg="$(echo "$pkg" | tr -d ' \r')"
      [ -z "$pkg" ] && { echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; }
      if ! konfirmasi "Aktifkan kembali $pkg?"; then echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; fi
      echo
      enable_paket "$pkg"
      ;;
    3)
      echo
      echo -e "${C_BIRU}File cadangan tersedia:${C_RESET}"
      local files=("$BACKUP_DIR"/backup-*.txt)
      if [ ! -e "${files[0]}" ]; then
        echo -e "${C_KUNING}Belum ada file cadangan.${C_RESET}"; tekan_enter; return
      fi
      local i=1
      for f in "${files[@]}"; do
        echo "  $i) $(basename "$f")"
        i=$((i+1))
      done
      echo -ne "${C_KUNING}Pilih nomor cadangan: ${C_RESET}"
      read -r n
      case "$n" in ''|*[!0-9]*) echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return ;; esac
      if [ "$n" -lt 1 ] || [ "$n" -gt "${#files[@]}" ]; then
        echo -e "${C_ABU}Pilihan tidak valid.${C_RESET}"; tekan_enter; return
      fi
      local file="${files[$((n-1))]}"
      echo -e "${C_BIRU}Memulihkan dari: $(basename "$file")${C_RESET}"
      echo -e "${C_ABU}Catatan: hanya mengaktifkan paket yang ada di cadangan.${C_RESET}"
      if ! konfirmasi "Yakin lanjut?"; then echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; fi
      echo
      local sukses=0
      while read -r pkg; do
        pkg="$(echo "$pkg" | tr -d ' \r')"
        [ -z "$pkg" ] && continue
        case "$pkg" in \#*) continue ;; esac
        enable_paket "$pkg" && sukses=$((sukses+1))
      done < "$file"
      garis
      echo -e "${C_HIJAU}Selesai. $sukses aplikasi diaktifkan kembali.${C_RESET}"
      log_aksi "RESTORE dari $file: $sukses diaktifkan"
      ;;
    *) return ;;
  esac
  tekan_enter
}

# ============================================================
#  BACKUP DAFTAR PAKET (manual)
# ============================================================
menu_backup() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  echo -e "${C_BIRU}Membuat cadangan daftar aplikasi...${C_RESET}"
  local bk
  bk="$(buat_backup)"
  local jumlah
  jumlah="$(grep -vc '^#' "$bk")"
  echo -e "  Tersimpan: ${C_HIJAU}$bk${C_RESET}"
  echo -e "  Jumlah paket tercatat: ${C_HIJAU}$jumlah${C_RESET}"
  log_aksi "BACKUP manual dibuat: $bk ($jumlah paket)"
  tekan_enter
}

# ============================================================
#  LIHAT LOG
# ============================================================
menu_log() {
  judul
  echo -e "${C_BIRU}Catatan Aktivitas (50 baris terakhir)${C_RESET}"
  garis
  if [ -s "$LOG_FILE" ]; then
    tail -n 50 "$LOG_FILE"
  else
    echo -e "${C_ABU}Belum ada catatan aktivitas.${C_RESET}"
  fi
  garis
  echo -e "${C_ABU}File log lengkap: $LOG_FILE${C_RESET}"
  tekan_enter
}

# ============================================================
#  CEK STATUS DEBLOAT (aktif vs nonaktif)
# ============================================================
menu_cek_status() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  deteksi_device
  echo -e "${C_BIRU}Status aplikasi bawaan yang dikenali${C_RESET}"
  garis

  # Daftar paket yang sedang DINONAKTIFKAN di HP
  local nonaktif
  nonaktif="$(rish_run "pm list packages -d" 2>/dev/null | sed 's/^package://' | tr -d '\r' | sort)"
  local terpasang
  terpasang="$(scan_paket_terpasang)"

  local jml_off=0 jml_on=0
  printf "  %-45s %s\n" "PAKET" "STATUS"
  garis
  while IFS='|' read -r pkg nama risk; do
    pkg="$(echo "$pkg" | tr -d ' \r')"
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    echo "$terpasang" | grep -qx "$pkg" || continue
    if echo "$nonaktif" | grep -qx "$pkg"; then
      printf "  %-45s ${C_KUNING}%s${C_RESET}\n" "$pkg" "NONAKTIF"
      jml_off=$((jml_off+1))
    else
      printf "  %-45s ${C_HIJAU}%s${C_RESET}\n" "$pkg" "aktif"
      jml_on=$((jml_on+1))
    fi
  done < <(baca_semua_database)
  garis
  echo -e "  Sudah dinonaktifkan: ${C_KUNING}${jml_off}${C_RESET}   |   Masih aktif: ${C_HIJAU}${jml_on}${C_RESET}"
  log_aksi "CEK STATUS: $jml_off nonaktif, $jml_on aktif"
  tekan_enter
}

# ============================================================
#  CARI APLIKASI (berdasarkan kata kunci)
# ============================================================
menu_cari() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  echo -e "${C_BIRU}Cari Aplikasi${C_RESET}"
  echo -e "${C_ABU}Ketik kata kunci (nama atau nama paket). Contoh: facebook, music${C_RESET}"
  echo
  echo -ne "${C_KUNING}Kata kunci: ${C_RESET}"
  read -r kw
  kw="$(echo "$kw" | tr '[:upper:]' '[:lower:]' | tr -d '\r')"
  [ -z "$kw" ] && { echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; }

  deteksi_device
  local terpasang hasil=()
  terpasang="$(scan_paket_terpasang)"
  while IFS='|' read -r pkg nama risk; do
    pkg="$(echo "$pkg" | tr -d ' \r')"
    [ -z "$pkg" ] && continue
    case "$pkg" in \#*) continue ;; esac
    local baris_lc
    baris_lc="$(echo "$pkg $nama" | tr '[:upper:]' '[:lower:]')"
    if echo "$baris_lc" | grep -q "$kw"; then
      echo "$terpasang" | grep -qx "$pkg" && hasil+=("$pkg|$nama|$risk")
    fi
  done < <(baca_semua_database)

  garis
  if [ "${#hasil[@]}" -eq 0 ]; then
    echo -e "${C_KUNING}Tidak ada aplikasi cocok & terpasang untuk: '$kw'${C_RESET}"
    tekan_enter; return
  fi
  echo -e "${C_BIRU}Hasil pencarian:${C_RESET}"
  local i=1
  for item in "${hasil[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    printf "  %2d) %-22s ${C_ABU}(%s, %s)${C_RESET}\n" "$i" "$nama" "$pkg" "$risk"
    i=$((i+1))
  done
  garis
  echo -ne "${C_KUNING}Nomor yang ingin dinonaktifkan (spasi, kosong=batal): ${C_RESET}"
  read -r pilihan
  [ -z "$pilihan" ] && { echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; }

  local terpilih=()
  for n in $pilihan; do
    case "$n" in ''|*[!0-9]*) continue ;; esac
    [ "$n" -ge 1 ] && [ "$n" -le "${#hasil[@]}" ] && terpilih+=("${hasil[$((n-1))]}")
  done
  [ "${#terpilih[@]}" -eq 0 ] && { echo -e "${C_ABU}Tidak ada pilihan valid.${C_RESET}"; tekan_enter; return; }

  echo
  for item in "${terpilih[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    printf "  - %-22s ${C_ABU}(%s)${C_RESET}\n" "$nama" "$pkg"
  done
  if ! konfirmasi "Yakin lanjut?"; then echo -e "${C_ABU}Dibatalkan.${C_RESET}"; tekan_enter; return; fi
  local bk; bk="$(buat_backup)"; echo -e "  Cadangan: ${C_HIJAU}$bk${C_RESET}"; log_aksi "BACKUP (cari): $bk"
  echo
  local sukses=0
  for item in "${terpilih[@]}"; do
    IFS='|' read -r pkg nama risk <<< "$item"
    disable_paket "$pkg" && sukses=$((sukses+1))
  done
  garis
  echo -e "${C_HIJAU}Selesai. $sukses aplikasi diproses.${C_RESET}"
  log_aksi "CARI selesai: $sukses diproses"
  tekan_enter
}

# ============================================================
#  APLIKASI TAK DIKENAL (belum ada di database)
#  Membantu menemukan bloatware baru untuk dilaporkan.
# ============================================================
menu_tak_dikenal() {
  judul
  if ! cek_dependency; then tekan_enter; return; fi
  garis
  deteksi_device
  echo -e "${C_BIRU}Aplikasi terpasang yang BELUM ada di database${C_RESET}"
  echo -e "${C_ABU}Hanya menampilkan aplikasi pihak ketiga (non-android inti).${C_RESET}"
  garis

  # daftar paket yang dikenal database
  local dikenal
  dikenal="$(baca_semua_database | cut -d'|' -f1 | tr -d ' \r' | sort -u)"
  local terpasang
  terpasang="$(scan_paket_terpasang)"

  local out="$DIR/logs/tak-dikenal-$(date '+%Y%m%d-%H%M%S').txt"
  local jml=0
  {
    echo "# Aplikasi terpasang yang belum ada di database"
    echo "# Brand: $BRAND | Model: $MODEL"
    echo "# Format siap salin: package|nama aplikasi|risk"
  } > "$out"

  while read -r pkg; do
    [ -z "$pkg" ] && continue
    # lewati paket yang sudah dikenal
    echo "$dikenal" | grep -qx "$pkg" && continue
    # lewati whitelist
    ada_di_whitelist "$pkg" && continue
    # tampilkan terutama yang tampak vendor/oem (heuristik sederhana)
    echo -e "  ${C_ABU}$pkg${C_RESET}"
    echo "$pkg|(isi nama)|safe" >> "$out"
    jml=$((jml+1))
  done <<< "$terpasang"

  garis
  echo -e "  Total belum dikenal: ${C_HIJAU}${jml}${C_RESET}"
  echo -e "  Daftar disimpan ke: ${C_HIJAU}$out${C_RESET}"
  echo -e "${C_ABU}Kamu bisa edit file itu lalu salin barisnya ke database merek.${C_RESET}"
  log_aksi "TAK DIKENAL: $jml paket, disimpan $out"
  tekan_enter
}

# ============================================================
#  MODE SIMULASI (Dry-Run) on/off
# ============================================================
toggle_simulasi() {
  if [ "$DRY_RUN" -eq 1 ]; then
    DRY_RUN=0
    echo -e "${C_HIJAU}Mode Simulasi DIMATIKAN. Aksi akan benar-benar dijalankan.${C_RESET}"
  else
    DRY_RUN=1
    echo -e "${C_KUNING}Mode Simulasi DINYALAKAN. Aksi hanya pura-pura (aman untuk coba-coba).${C_RESET}"
  fi
  log_aksi "Mode simulasi diubah -> DRY_RUN=$DRY_RUN"
  sleep 1
}

# ============================================================
#  MENU UTAMA
# ============================================================
menu_utama() {
  while true; do
    judul
    if [ "$DRY_RUN" -eq 1 ]; then
      echo -e "${C_KUNING}>> MODE SIMULASI ON (cuma coba-coba) <<${C_RESET}\n"
    fi
    echo -e "${C_BIRU}Mau ngapain?${C_RESET}"
    echo
    echo "   1) Cek HP"
    echo "   2) Debloat Aman"
    echo "   3) Debloat Disarankan"
    echo "   4) Pilih Sendiri"
    echo "   5) Cari Aplikasi"
    echo "   6) Cek Status"
    echo "   7) Aplikasi Tak Dikenal"
    echo "   8) Balikin Aplikasi"
    echo "   9) Backup Daftar"
    echo "  10) Lihat Log"
    echo "  11) Mode Simulasi (on/off)"
    echo "   0) Keluar"
    echo
    echo -ne "${C_KUNING}Pilih (nomor menu): ${C_RESET}"
    read -r pil
    case "$pil" in
      1) menu_scan_hp ;;
      2) menu_safe_debloat ;;
      3) menu_recommended_debloat ;;
      4) menu_manual_debloat ;;
      5) menu_cari ;;
      6) menu_cek_status ;;
      7) menu_tak_dikenal ;;
      8) menu_restore ;;
      9) menu_backup ;;
      10) menu_log ;;
      11) toggle_simulasi ;;
      0)
        judul
        echo -e "${C_HIJAU}Terima kasih sudah memakai Android Universal Debloat.${C_RESET}"
        echo -e "${C_ABU}Sampai jumpa! HP kamu kini lebih ringan. :)${C_RESET}"
        echo
        log_aksi "Keluar dari aplikasi"
        exit 0
        ;;
      *)
        echo -e "${C_MERAH}Nomornya gak ada bro, coba lagi.${C_RESET}"
        sleep 1
        ;;
    esac
  done
}

# ============================================================
#  MULAI
# ============================================================
log_aksi "Aplikasi dijalankan"
judul
check_update "$@"
ketik "   Menyalakan AUD..." 0.02
loading "Cek perlengkapan"
sleep 0.2
menu_utama
