# i-Panel kaynak deposu

i-Panel, macOS menü çubuğunda çalışan küçük bir durum göstergesi ve hızlı kontrol panelidir. Bu depo Swift/Xcode kaynaklarını içerir; indirilebilir uygulama paketi ve kurulum bilgileri açık [i-Panel](https://github.com/enesmisirlioglu0/i-Panel) deposunda yayımlanır.

Kaynak kod [MIT Lisansı](LICENSE) ile sunulur: kullanabilir, değiştirebilir ve dağıtabilirsiniz; lisans metni ve telif bildirimi korunmalıdır.

## 1.2 (Build 3)

- Hedef: macOS 13 ve sonrası
- Mimari: SwiftUI `MenuBarExtra(.window)`; ayarlar penceresi ve yerel macOS davranışları için AppKit
- Menü çubuğu: macOS'un açık/koyu görünüme uyum sağlayan yerleşik tek renkli üçlü-kart sembolü
- Finder / DMG simgesi: kırmızı, mavi ve yeşil üç karttan oluşan i-Panel işareti
- Yerel kabul testi: menü simgesi ve panel, `Ayar`, `Sıfırla` ve doğrudan sürükle-bırak sıralama geliştirici Mac'inde onaylandı.
- Dağıtım paketi: imzasız, noterlenmemiş, universal (`arm64` + `x86_64`) DMG

## Faz 1: simülasyon paneli

- CPU, bellek, disk, batarya sıcaklığı/durumu ve anlık indirme/yükleme için beş kart
- 1 / 3 / 5 saniyelik yenileme aralığıyla güncellenen, inandırıcı fakat tamamen simüle edilmiş değerler
- Kartları istediğiniz anda doğrudan sürükle-bırakla sıralama, sırayı yerelde hatırlama ve varsayılan sıraya dönme
- Alt sağda `Ayar` ve `Sıfırla` düğmeleri
- Dock simgesini göster/gizle, girişte açılma isteği, kart sırasını hatırlama ve yenileme sıklığı ayarları

Bu faz gerçek CPU, bellek, disk, batarya veya ağ verisi toplamaz; kart değerleri simülasyondur. Uygulama ağa bağlanmaz, bulut hesabı kullanmaz ve tercihler yalnızca bu Mac'te saklanır.

## İmzasız DMG oluşturma

```zsh
zsh scripts/create-unsigned-dmg.zsh
```

Betik `Release` yapılandırmasını hem Apple Silicon hem Intel için üretir, imzalamayı kapatır ve şunu oluşturur:

```text
dist/i-Panel-<sürüm>-build-<build>-unsigned.dmg
```

`dist/` ve `.dmg` dosyaları Git tarafından izlenmez. DMG yalnız açık depodaki GitHub Release varlığı olarak yayımlanır; Swift/Xcode kaynakları bu public depoda yer alır.

## Kurulum sınırı

İlk public paket Developer ID ile imzalanmış veya noterlenmiş değildir. macOS bir uyarı gösterirse kullanıcı uygulamayı `Applications` klasörüne taşıyıp Finder'da uygulamaya sağ tıklayarak **Aç** → **Aç** yolunu kullanmalıdır; Gatekeeper'ı kapatma yönlendirmesi verilmez.

`Girişte i-Panel’i aç` ayarı `SMAppService.mainApp` kullanır. macOS bu kayıt için geçerli uygulama imzası isteyebileceğinden imzasız public pakette bu ayar çalışmayabilir.

## Güvenlik ilkeleri

- Anahtar, parola, token, provisioning dosyası veya kişisel veri commit edilmez.
- Üçüncü taraf servis, CloudKit, App Group, giriş sistemi veya sistem izni eklenmeden önce ayrı kapsam ve onay gerekir.
- Açık `i-Panel` deposu belgeleri, ikon görselini ve GitHub Release DMG varlıklarını taşır; bu depo ise public Swift/Xcode kaynaklarını taşır.
