# i-Panel kaynak deposu

i-Panel, macOS menü çubuğunda çalışan küçük bir durum göstergesi ve hızlı kontrol panelidir. Bu depo Swift/Xcode kaynaklarını içerir; indirilebilir uygulama paketi ve kurulum bilgileri açık [i-Panel](https://github.com/enesmisirlioglu0/i-Panel) deposunda yayımlanır.

Kaynak kod [MIT Lisansı](LICENSE) ile sunulur: kullanabilir, değiştirebilir ve dağıtabilirsiniz; lisans metni ve telif bildirimi korunmalıdır.

## Geliştirme notu

i-Panel, proje sahibinin ürün fikri, kapsamı, görsel tercihleri ve gerçek Mac üzerindeki kabul testleri doğrultusunda geliştirildi. Swift/Xcode uygulama kodu, hata ayıklama ve dokümantasyon çalışmaları ise proje sahibinin yönlendirmesiyle **ChatGPT 5.6 Terra (OpenAI Codex)** yapay zekâ geliştirme asistanının desteği kullanılarak birlikte yürütüldü. Proje sahipliği ile tüm ürün ve yayın kararları proje sahibine aittir.

## 1.3 (Build 4)

- Hedef: macOS 13 ve sonrası
- Mimari: SwiftUI `MenuBarExtra(.window)`; ayarlar penceresi ve yerel macOS davranışları için AppKit
- Menü çubuğu: macOS'un açık/koyu görünüme uyum sağlayan yerleşik tek renkli üçlü-kart sembolü
- Finder / DMG simgesi: kırmızı, mavi ve yeşil üç karttan oluşan i-Panel işareti
- Gerçek sistem verileri: CPU, bellek, başlangıç diski, batarya doluluk/durumu ve Mac toplam ağ hızı
- Dağıtım paketi: imzasız, noterlenmemiş, universal (`arm64` + `x86_64`) DMG

## Gerçek sistem göstergeleri

- CPU: Mach `host_statistics` sayaçlarından iki örnek arasındaki gerçek toplam işlemci kullanımı
- Bellek: fiziksel RAM ve sanal bellek istatistiklerinden kullanılan/toplam kapasite
- Disk: başlangıç diskinin kullanılan/toplam kapasitesi; kullanıcı dosyaları taranmaz
- Batarya: gerçek doluluk yüzdesi ile şarj, adaptör veya batarya kullanım durumu; sıcaklık bu sürümde gösterilmez
- İnternet: etkin yerel ağ arayüzlerinin byte sayaçlarından Mac toplam indirme/yükleme hızı
- 1 / 3 / 5 saniyelik yenileme aralığı; CPU ve ağ ilk ölçümde uydurma değer yerine kısa süreliğine `Ölçülüyor…` gösterir
- Kartları istediğiniz anda doğrudan sürükle-bırakla sıralama, sırayı yerelde hatırlama ve varsayılan sıraya dönme
- Alt sağda `Ayar` ve `Sıfırla` düğmeleri
- Dock simgesini göster/gizle, girişte açılma isteği, kart sırasını hatırlama ve yenileme sıklığı ayarları

Bu göstergeler yalnızca uygulamanın çalıştığı Mac'te salt okunur public macOS API'leriyle ölçülür. i-Panel dışarıya ağ bağlantısı kurmaz, metrikleri veya kişisel verileri göndermez, bulut hesabı kullanmaz ve özel bir macOS izin penceresi istemez. Tercihler yalnızca bu Mac'te saklanır.

Masaüstü Mac'lerde dahili batarya bulunmuyorsa kart `Batarya yok` gösterir. VPN veya sanal ağ arayüzleri kullanıldığında ağ kartındaki toplam, kapsülleme nedeniyle küçük farklar içerebilir; gösterge uygulama bazlı değil Mac toplam trafiğidir.

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
- Gerçek metrikler üçüncü taraf servis, CloudKit, hesap, erişilebilirlik, Full Disk Access veya ağ paketi yakalama kullanmadan yerelde okunur.
- Açık `i-Panel` deposu belgeleri, ikon görselini ve GitHub Release DMG varlıklarını taşır; bu depo ise public Swift/Xcode kaynaklarını taşır.
