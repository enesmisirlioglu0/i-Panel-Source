# i-Panel

i-Panel, macOS menü çubuğunda çalışan küçük bir durum göstergesi ve hızlı kontrol panelidir.

## Başlangıç durumu

- Sürüm: `1.0 (Build 1)`
- Hedef: macOS 13 ve sonrası
- Arayüz: SwiftUI `MenuBarExtra`
- Derleme doğrulaması: 28 Ağustos 2026'da Xcode 26.6 ile, imzalama kapalı Faz 1 temiz macOS Debug derlemesi başarılı
- Manuel menü çubuğu etkileşim doğrulaması: Henüz yapılmadı
- Dağıtım: Henüz indirilebilir DMG veya GitHub Release yoktur.

Apple'ın kendi Denetim Merkezi içine üçüncü taraf modül eklemek için genel kullanıma açık bir API'si yoktur. i-Panel bu yüzden Denetim Merkezi'nin yanındaki menü çubuğunda, Apple'ın desteklediği `MenuBarExtra` yapısıyla çalışır.

## Faz 1: simülasyon paneli

- Menü çubuğunda i-Panel göstergesi
- Sağ üst simgeye bağlı, turkuaz tonlu büyük açılır panel
- CPU, bellek, disk, batarya sıcaklığı/durumu ve anlık indirme/yükleme için beş kart
- Her 1,5 saniyede güncellenen, inandırıcı fakat tamamen simüle edilmiş değerler
- Kartları her an doğrudan sürükle-bırak yöntemiyle taşıma ve varsayılan sıraya dönme
- Alt sağda `Ayar` ve `Sıfırla` denetimleri
- Panel dışındaki bir arayüz öğesine tıklanınca otomatik kapanan yerel macOS popover davranışı
- Ayarlardan kalıcı Dock simgesi görünürlüğü ve macOS girişinde açılma isteği

Bu faz gerçek CPU/bellek/disk/batarya/ağ verisi toplamaz, ağa bağlanmaz ve bulut hesabı kullanmaz. Sürükle-bırak sırası bu ilk aşamada yalnız açık oturum boyunca korunur. Dock görünürlüğü kullanıcı tercihidir; girişte açılma anahtarı yalnız kullanıcı onu açtığında macOS'a kayıt isteği yollar.

### Başlangıçta açılma sınırı

Bu ayar macOS 13+'ta `SMAppService.mainApp` kullanır. Apple bu kayıt için geçerli uygulama imzası ister; bu yüzden imzasız Debug/DMG paketi seçeneği hata veya kullanılamaz durumunu gösterebilir. İmzalı geliştirme paketiyle doğrulanmadan, imzasız public DMG için girişte açılma özelliği vaat edilmez.

## Xcode ile çalıştırma

1. `IPanel.xcodeproj` dosyasını Xcode'da açın.
2. Aktif şemanın `IPanel` olduğunu doğrulayın.
3. Mac hedefini seçip Run düğmesine basın.
4. Uygulama açıldığında menü çubuğundaki i-Panel simgesini seçin.

## Dağıtım planı

Proje tamamlandığında public `i-Panel` deposunun GitHub Releases alanına **imzasız** bir `.dmg` konması planlanır. Kaynak kod bu özel depoda kalır. İlk paket Developer ID ile imzalanmış veya noterlenmiş olmayacağından macOS Gatekeeper uyarısı beklenir; public kurulum notu, uygulamayı Uygulamalar klasörüne taşıma ve Finder'da sağ tıklayıp `Aç` seçeneğini kullanma adımlarını açıkça içerecektir.

Henüz DMG oluşturulmadı veya Release yayımlanmadı. Yayın, tamamlanan sürümün son görsel/işlev kontrolünden ve ayrıca verilen son yayın onayından sonra yapılır. İmzasız ilk pakette girişte açılma ayarının çalışmaması beklenebilir; bu özellik için ileride ayrı bir imzalama kararı gerekir.

Paketleme zamanı geldiğinde, yerel ve imzasız DMG şu betikle üretilecektir:

```zsh
zsh scripts/create-unsigned-dmg.zsh
```

Betik `dist/i-Panel-<sürüm>-unsigned.dmg` çıktısını üretir; GitHub'a hiçbir şey yüklemez ve var olan aynı isimli DMG'nin üzerine yazmayı reddeder.

## Depo sınırı

Bu klasör, özel `i-Panel-Source` kaynak deposu içindir. Swift/Xcode kaynakları, imzalama ayrıntıları veya ileride eklenecek hassas yapılandırmalar açık dokümantasyon deposuna taşınmaz.

## Güvenlik ilkeleri

- Anahtar, parola, token, provisioning dosyası veya kişisel veri commit edilmez.
- Üçüncü taraf servis, CloudKit, App Group, giriş sistemi veya sistem izni eklenmeden önce ayrı kapsam ve onay gerekir.
- Kamuya açık `i-Panel` deposu belgeleri ve ilerideki imzasız DMG Release varlıklarını barındırır; Swift/Xcode kaynakları içermez.
