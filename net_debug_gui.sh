#!/bin/bash

##############################################################################
# 1. Root (veya sudo) Yetkisi Kontrolü
##############################################################################
if [[ "$(id -u)" -ne 0 ]]; then
    echo "Bu betik root (veya sudo) yetkisiyle çalıştırılmalıdır."
    exit 1
fi

##############################################################################
# 2. Gerekli Komutların (Bağımlılıkların) Kontrolü
##############################################################################
REQUIRED_CMDS=("yad" "speedtest-cli" "ethtool" "dig" "systemctl" "dhclient" "curl")

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Hata: '$cmd' komutu sistemde bulunamadı. Lütfen gerekli paketi yükleyin."
        exit 1
    fi
done

##############################################################################
# 3. Log Dosyaları
##############################################################################
LOG_FILE="/var/log/ag_tespit.log"
DETAY_LOG="/tmp/ag_tespit_detay.log"
AG_GECMIS_LOG="/var/log/ag_geçmiş.log"

> "$LOG_FILE"
> "$DETAY_LOG"

##############################################################################
# 4. Renk Tanımları (Sadece terminal logu için ister kullanın ister kaldırın)
##############################################################################
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

##############################################################################
# 5. Log Yazma Fonksiyonları
##############################################################################
log_yaz() {
    # Terminal ve /var/log dosyasına renkli yazabilirsiniz;
    # YAD'a iletilecek mesajlarda ise renk kodu kullanmayın.
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$AG_GECMIS_LOG"
}

detay_log_yaz() {
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$DETAY_LOG"
    echo -e "🔧 Komut: $1" >> "$DETAY_LOG"
    echo -e "📝 Çıktı:\n$2" >> "$DETAY_LOG"
}

##############################################################################
# 6. Ağ Hız Testi
##############################################################################
hiz_testi_yap() {
    (
        echo "10" ; sleep 1
        echo "# İnternet hızı ölçülüyor..."
        result=$(speedtest-cli --simple 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "100" ; sleep 1
            yad --width=400 --height=200 --title "Hız Testi" --text="\n${result}" --button="Tamam:0"
        else
            echo "100" ; sleep 1
            yad --width=400 --height=200 --title "Hata" --text="Hız testi başarısız!" --button="Tamam:0"
        fi
    ) | yad --progress --title="Lütfen Bekleyin" --text="Hız testi yapılıyor..." --percentage=0 --auto-close
}

##############################################################################
# 7. Otomatik Onarım
##############################################################################
otomatik_onarim() {
    log_yaz "Otomatik onarım başlatıldı"
    
    systemctl restart NetworkManager 2>&1 | tee -a "$DETAY_LOG"
    dhclient -r 2>&1 | tee -a "$DETAY_LOG"
    dhclient 2>&1 | tee -a "$DETAY_LOG"

    if command -v systemd-resolve &>/dev/null; then
        systemd-resolve --flush-caches 2>&1 | tee -a "$DETAY_LOG"
    fi
    
    yad --width=400 --height=100 --title "Bilgi" --text="Otomatik onarım işlemleri tamamlandı" --button="Tamam:0"
}

##############################################################################
# 8. Ağ Arayüzü Seçimi
##############################################################################
ag_arayuz_sec() {
    # /sys/class/net/ altında "lo" hariç tüm arayüzleri döneriz
    up_ifaces=()
    for iface in $(ls /sys/class/net | grep -vx 'lo'); do
        # operstate dosyası, o anki arayüz durumunu içerir (up, down, dormant vb.)
        state=$(cat /sys/class/net/$iface/operstate 2>/dev/null)

        # Eğer durumu "up" ise diziye ekleyelim
        if [[ "$state" == "up" ]]; then
            up_ifaces+=("$iface")
        fi
    done

    # Eğer hiç UP arayüz bulunamadıysa uyarı gösterip çıkalım
    if [[ ${#up_ifaces[@]} -eq 0 ]]; then
        yad --error --text="Aktif (UP) durumunda bir ağ arayüzü bulunamadı! Lütfen wifi veya internet kablonuzun takılı olduğundan emin olun"
        echo ""
        return
    fi

    # YAD listesine dönüştür
    selected=$(yad --center --width=300 --height=200 --title "Ağ Arayüzü Seç" \
        --list --column="Arayüzler" "${up_ifaces[@]}" \
        --print-column=1 \
        --separator="\n" \
        --button="Seç:0" --button="İptal:1")

    # İptal edilirse boş string dön
    if [[ $? -ne 0 ]]; then
        echo ""
        return
    fi

    # Bazen sondaki "|" karakterini temizlemek gerekebilir
    selected=$(echo "$selected" | tr -d '|')
    echo "$selected"
}

##############################################################################
# 9. Hata İpuçları
##############################################################################
hata_ipucu() {
    case $1 in
        1) echo "🔧 1. Katman Çözümleri:\n- Ethernet kablosunu yeniden takın\n- WiFi anahtarını kontrol edin\n- Router güç durumunu kontrol edin" ;;
        2) echo "🔧 2. Katman Çözümleri:\n- ip link set <arayüz> up\n- MAC çakışmasını kontrol edin\n- Sürücü güncelleyin" ;;
        3) echo "🔧 3. Katman Çözümleri:\n- DHCP sunucusunu kontrol edin\n- Statik IP deneyin\n- ip addr add 192.168.x.x/24 dev <arayüz>" ;;
        4) echo "🔧 4. Katman Çözümleri:\n- Güvenlik duvarı kurallarını inceleyin\n- iptables -F (dikkatli olun)\n- route -n ile yönlendirme tablosunu kontrol edin" ;;
        5) echo "🔧 5. Katman Çözümleri:\n- /etc/resolv.conf içeriğini kontrol edin\n- dig @8.8.8.8 google.com\n- DNS sunucusunu 8.8.8.8 yapın" ;;
        7) echo "🔧 7. Katman Çözümleri:\n- curl -v https://google.com ile detaylı test\n- Proxy ayarlarını inceleyin\n- SSL sertifikalarını güncelleyin" ;;
    esac
}

##############################################################################
# 10. Ağ Testi
##############################################################################
ag_testi_yap() {
    local hata_katmani=0
    local hata_mesaji=""
    local selected_interface

    selected_interface=$(ag_arayuz_sec)
    [ -z "$selected_interface" ] && return

    log_yaz "Seçilen arayüz: $selected_interface"
    log_yaz "Ağ testi başlatıldı."

    # 1. Katman (sadece kablolu arayüz)
    if [[ "$selected_interface" =~ ^(eth|en|eno|ens) ]]; then
        cmd="ethtool $selected_interface"
        output=$(eval "$cmd" 2>&1)
        detay_log_yaz "$cmd" "$output"
        if ! echo "$output" | grep -q "Link detected: yes"; then
            hata_katmani=1
            hata_mesaji="⚠️ 1. Katman Hatası: $selected_interface fiziksel bağlantı yok!"
            show_error
            return
        fi
    else
        log_yaz "Kablosuz/farklı isimli arayüz, ethtool 'Link detected' kontrolü atlandı."
    fi

    # 2. Katman (MAC)
    cmd="ip link show $selected_interface"
    output=$(eval "$cmd" 2>&1)
    detay_log_yaz "$cmd" "$output"

    macaddr=$(cat /sys/class/net/$selected_interface/address 2>/dev/null)
    if [[ -z "$macaddr" || "$macaddr" =~ ^(00:00:00:00:00:00)$ ]]; then
        hata_katmani=2
        hata_mesaji="⚠️ 2. Katman Hatası: MAC adresi tanımsız!"
        show_error
        return
    fi

    # 3. Katman (IP)
    cmd="ip addr show $selected_interface"
    output=$(eval "$cmd" 2>&1)
    detay_log_yaz "$cmd" "$output"
    if ! echo "$output" | grep -q "inet "; then
        hata_katmani=3
        hata_mesaji="⚠️ 3. Katman Hatası: IP adresi alınamadı!"
        show_error
        return
    fi

    # 4. Katman (Ping)
    cmd="ping -c 3 -I $selected_interface 8.8.8.8"
    output=$(eval "$cmd" 2>&1)
    detay_log_yaz "$cmd" "$output"
    if ! echo "$output" | grep -q "time="; then
        hata_katmani=4
        hata_mesaji="⚠️ 4. Katman Hatası: İnternet erişimi yok!"
        show_error
        return
    fi

    # 5. Katman (DNS)
    cmd="dig +short @8.8.8.8 google.com"
    output=$(eval "$cmd" 2>&1)
    detay_log_yaz "$cmd" "$output"
    if [[ -z "$output" ]]; then
        hata_katmani=5
        hata_mesaji="⚠️ 5. Katman Hatası: DNS çözümleme başarısız!"
        show_error
        return
    fi

    # 7. Katman (HTTP/HTTPS) -> -L ile redirect takip
    cmd="curl -s -L -o /dev/null -w '%{http_code}' --interface $selected_interface https://google.com"
    output=$(eval "$cmd" 2>&1)
    detay_log_yaz "$cmd" "$output"
    if [ "$output" != "200" ]; then
        hata_katmani=7
        hata_mesaji="⚠️ 7. Katman Hatası: HTTPS erişimi başarısız! (Kod: $output)"
        show_error
        return
    fi

    # Başarılı
    local ip_addr
    ip_addr=$(ip -4 addr show "$selected_interface" | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

    # Burada ANSI kodu yerine düz metin kullanıyoruz:
    hata_mesaji="✓ Tüm testler başarılı!\n\nIP: $ip_addr\nMAC: $macaddr"
    yad --width=450 --height=200 --title "Test Sonucu" --text="$hata_mesaji" \
        --button="Hız Testi:2" --button="Rapor Oluştur:1" --button="Kapat:0"

    case $? in
        1)
            report_file="/tmp/ag_rapor_$(date +%s).txt"
            cp "$DETAY_LOG" "$report_file"
            yad --width=600 --height=500 --title "Detaylı Rapor" --text-info --filename="$report_file" --button="Kapat:0"
            ;;
        2)
            hiz_testi_yap
            ;;
    esac
}

##############################################################################
# 11. Hata Gösterimi
##############################################################################
show_error() {
    action=$(yad --width=400 --height=300 --title "Hata Tespit Edildi" \
        --text="$hata_mesaji" \
        --button="Otomatik Onarım:2" \
        --button="İpucu Göster:1" \
        --button="Kapat:0")

    case $? in
        1)
            ipucu=$(hata_ipucu $hata_katmani)
            yad --width=500 --height=300 --title "Çözüm İpuçları" --text="$ipucu" --button="Kapat:0"
            ;;
        2)
            otomatik_onarim
            ag_testi_yap
            ;;
    esac
}

##############################################################################
# 12. Ana Menü
##############################################################################
main_menu() {
    yad --center --width=400 --height=200 --title "Ağ Tanılama Aracı" \
        --text="<span font='14' weight='bold'>🌐 AĞ TANILAMA MERKEZİ</span>\n\nLütfen bir işlem seçin:" \
        --button="🛠️ Ağ Testi Başlat:0" \
        --button="📊 Hız Testi:1" \
        --button="📂 Geçmiş Logları:2" \
        --button="❌ Çıkış:3"

    case $? in
        0) ag_testi_yap ;;
        1) hiz_testi_yap ;;
        2)
           yad --width=800 --height=500 --title "Geçmiş Logları" --text-info --filename="$AG_GECMIS_LOG" --button="Kapat:0"
           ;;
        3) exit 0 ;;
    esac
}

while true; do
    main_menu
done

