# Ağ Teşhis ve Sorun Giderme Aracı (GUI)

## 📌 Proje Hakkında
Bu betik, Debian tabanlı sistemler için grafik arayüzlü bir ağ test aracı sağlar. Ağ bağlantısında yaşanan sorunları OSI modeline göre analiz eder ve kullanıcıya detaylı teşhis imkanı sunar. GUI (grafik arayüzü) sayesinde kullanıcılar terminal komutlarına ihtiyaç duymadan ağ testlerini gerçekleştirebilirler.

---

## 🚀 Özellikler
- **Ağ Bağlantısı Testi**: OSI katmanlarına göre internet bağlantı analizi yapar.
- **Bağımlılık Kontrolü**: Çalışması için gerekli komutların sistemde bulunup bulunmadığını kontrol eder.
- **Root Yetkisi Gereksinimi**: Betik, belirli işlemler için root yetkisiyle çalıştırılmalıdır.
- **GUI Desteği**: Kullanıcı dostu bir arayüz sunar.

---

## 🛠 Gerekli Bağımlılıklar
Bu betiğin çalışması için aşağıdaki paketlerin sisteminizde kurulu olması gerekir:

```bash
sudo apt install yad speedtest-cli ethtool dnsutils systemd dhclient curl -y
```

Alternatif olarak, tek tek aşağıdaki komutları çalıştırarak eksik paketleri yükleyebilirsiniz:

```bash
sudo apt install yad
sudo apt install speedtest-cli
sudo apt install ethtool
sudo apt install dnsutils
sudo apt install systemd
sudo apt install dhclient
sudo apt install curl
```

---

## ⏳ Kurulum

1. Depoyu klonlayın veya betik dosyasını indirin:
   ```bash
   git clone https://github.com/doranali/Net_Debug_Gui.git
   ```
2. Betiğe çalıştırma izni verin:
   ```bash
   chmod +x net_debug_gui.sh
   ```
3. Betiği çalıştırın:
   ```bash
   sudo ./net_debug_gui.sh
   ```

---

## 🖥 Kullanım

Uygulama açılış ekranı aşağıdaki gibidir. Burada ağ testi başlatıp herhangi bir sorun olup olmadığına bakabilir, hız testi yapabilir veya daha önceden başlattığınız testler hakkında bilgi alabilirsiniz.

![Ağ Testi Ana Ekran](https://github.com/user-attachments/assets/9f4c513f-263e-4d77-b38b-0df046dc7b93)

Ağ testi başlatıldığında burada aktif olan ağ kartınız gözükecektir. Birden fazla ağ kartınız var ise seçim yapabilirsiniz.

![image](https://github.com/user-attachments/assets/76c90892-2830-4d09-9c91-d3126c5f5f4b)


Eğer ağınızda herhangi bir sorun yok ise karşınıza bu şekilde sonuç penceresi açılacaktır.

![image](https://github.com/user-attachments/assets/54bafd67-597a-452a-8fa4-39322464e609)


Eğer Wi-Fi’nizi açmayı unutup ağ testini başlattığınızda uygulama bunu algılayıp uyarı verecektir.

![image](https://github.com/user-attachments/assets/bab984b2-dda9-4b5c-9238-f1e6bbbc4a95)


Başka bir senaryo daha düşünelim. Diyelim ki IP adresinizi statik olarak kendiniz tanımladınız ve bu IP adresi bulunduğunuz ağ içerisinde geçerli değil. Ağ testini başlattığınızda:

![Geçersiz IP Adresi Hatası](https://github.com/user-attachments/assets/d54f171b-4734-4f4a-a418-46654c101d38)

![Hata Mesajı](https://github.com/user-attachments/assets/2bfd3818-46e4-4d75-b88d-19c6a9371a11)

Bu hatayla karşılaşacaksınız ve "Onar" butonuna bastığınızda uygulama otomatik olarak sorununuzu çözecektir. Lütfen onarımın tamamlanması için yaklaşık **30 saniye** bekleyiniz. "Rapor Oluştur" kısmından da arka planda çalışan tüm kodları inceleyebilir ve daha ayrıntılı bilgiler edinebilirsiniz.

![image](https://github.com/user-attachments/assets/f762ba9b-4497-4ef8-a932-3004e707f55d)


Ayrıca uygulama başlangıç kısmında bulunan "Geçmiş Loglar" bölümünden uygulamanın çalışma günlüğünü ulaşabilirsiniz.

![Log Kayıtları](https://github.com/user-attachments/assets/1c746c7b-f0e4-4e3d-a3d7-8da67d0d3ce5)

---

## 📂 Dosya Yapısı
- **net_debug_gui.sh** → Ana betik dosyası
- **README.md** → Proje hakkında bilgi ve kullanım rehberi

---

## 📌 Lisans
Bu proje açık kaynak olup eğitim ve akademik çalışmalar için kullanılabilir. Kullanım sırasında kaynak gösterilmesi tavsiye edilir.
