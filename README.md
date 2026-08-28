# i-Panel

i-Panel, macOS menü çubuğunda çalışan küçük bir durum göstergesi ve hızlı kontrol panelidir.

## Başlangıç durumu

- Sürüm: `1.0 (Build 1)`
- Hedef: macOS 13 ve sonrası
- Arayüz: SwiftUI `MenuBarExtra`
- Derleme doğrulaması: 28 Ağustos 2026'da Xcode 26.6 ile, imzalama kapalı temiz macOS Debug derlemesi başarılı
- Manuel menü çubuğu etkileşim doğrulaması: Henüz yapılmadı
- Dağıtım: Yerel Xcode iskeleti; TestFlight veya App Store sürümü değildir.

Apple'ın kendi Denetim Merkezi içine üçüncü taraf modül eklemek için genel kullanıma açık bir API'si yoktur. i-Panel bu yüzden Denetim Merkezi'nin yanındaki menü çubuğunda, Apple'ın desteklediği `MenuBarExtra` yapısıyla çalışır.

## İlk iskeletin kapsamı

- Menü çubuğunda i-Panel göstergesi
- Açılır küçük kontrol penceresi
- Odak modu, tasarruf modu ve panel seviyesi için **yerel önizleme** kontrolleri
- Son yenileme zamanını gösteren durum alanı

Bu ilk kontroller macOS sistem ayarlarını değiştirmez, sistem verisi toplamaz, ağa bağlanmaz ve bulut hesabı kullanmaz.

## Xcode ile çalıştırma

1. `IPanel.xcodeproj` dosyasını Xcode'da açın.
2. Aktif şemanın `IPanel` olduğunu doğrulayın.
3. Mac hedefini seçip Run düğmesine basın.
4. Uygulama açıldığında menü çubuğundaki i-Panel simgesini seçin.

## Depo sınırı

Bu klasör, özel `i-Panel-Source` kaynak deposu içindir. Swift/Xcode kaynakları, imzalama ayrıntıları veya ileride eklenecek hassas yapılandırmalar açık dokümantasyon deposuna taşınmaz.

## Güvenlik ilkeleri

- Anahtar, parola, token, provisioning dosyası veya kişisel veri commit edilmez.
- Üçüncü taraf servis, CloudKit, App Group, giriş sistemi veya sistem izni eklenmeden önce ayrı kapsam ve onay gerekir.
- Kamuya açık `i-Panel` deposu yalnızca belgeleri barındırır.
