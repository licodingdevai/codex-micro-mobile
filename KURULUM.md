# Codex Micro iPhone kurulumu

Bu repo iki parçayı birlikte içerir:

- Mac/Windows üzerinde Codex'e bağlanan yerel bridge;
- iPhone'da çalışan SwiftUI Codex Micro uygulaması.

Hazır DMG veya Companion uygulaması yoktur. Bridge ve iPhone uygulaması kaynak
koddan kurulur. Bağlantı Accessibility, klavye taklidi ya da sanal HID
kullanmaz; Codex'in yerel Micro olaylarını iletir.

## Gerekenler

- Mac'te kurulu Codex masaüstü uygulaması.
- Xcode ve iOS 17 veya üzeri bir iPhone.
- Node.js 20 veya üzeri. macOS launcher gerekirse Codex'in içindeki uyumlu Node
  runtime'ını da bulabilir.
- İlk eşleştirmede Mac ve iPhone'un aynı özel Wi-Fi ağında olması.

## 1. Repoyu indir ve bridge'i derle

```zsh
git clone https://github.com/licodingdevai/codex-micro-mobile.git
cd codex-micro-mobile
npm ci
npm run build
```

## 2. Eşleştirme QR'ını üret

```zsh
chmod +x release/codex-deck-launcher-macos/start-codex-deck.sh
release/codex-deck-launcher-macos/start-codex-deck.sh mobile-local-config
```

Bu komut bridge için yerel TLS sertifikası ve rastgele bir eşleştirme tokenı
oluşturur. QR kodunu, tokenı veya oluşturulan state dosyalarını paylaşma ve
repoya ekleme.

## 3. iPhone uygulamasını kur

Kendine ait benzersiz bir bundle ID oluştur:

```zsh
./scripts/configure-ios-signing.sh com.seninadın.CodexMicro
open ios/CodexDeckMobile.xcodeproj
```

Xcode'da:

1. `CodexDeckMobile` ve `CodexDeckWidgets` hedeflerinde kendi Team hesabını seç.
2. Hedef cihaz olarak fiziksel iPhone'u seç.
3. **Product > Run** komutunu çalıştır.
4. iPhone Yerel Ağ izni isterse izin ver.

`ios/Configuration/Local.xcconfig` yalnızca senin bilgisayarında oluşur ve Git
tarafından yok sayılır.

## 4. Telefonu eşleştir

Bridge'in ürettiği QR kodunu iPhone Kamera uygulamasıyla tara ve
**Codex Micro'da Aç** seçeneğine dokun. Sertifika parmak izi ve token Keychain'e
kaydedilir; sonraki açılışlarda aynı bridge'e otomatik bağlanır.

Bu eşleştirme Codex'in resmi Remote pairing özelliği değildir. Yalnızca bu
open-source iPhone uygulaması ile yerel bridge arasındaki bağlantıdır.

## Bridge'i başlat

Derleme sonrasında:

```zsh
release/codex-deck-launcher-macos/start-codex-deck.sh start
```

Codex normal biçimde açıksa bridge ilk bağlantı için kontrollü bir yeniden
başlatma isteyebilir. Gönderilmemiş metnini kaydetmeden bunu yapma.

Detaylı İngilizce rehber:
[docs/IOS_INSTALL.md](docs/IOS_INSTALL.md).
