# Atlas

**Atlas — mekdep we ofis harytlary** (okul ve ofis malzemeleri), Türkmenistan merkezli bir e-ticaret markasının resmi mobil uygulaması. Flutter ile geliştirilmiş, Android ve iOS'u tek koddan hedefleyen bir alışveriş uygulaması.

> Not: Bu README, [atlas.com.tm](https://atlas.com.tm) sitesinin canlı içeriği yerine proje kod tabanından (API uçları, çeviri dosyaları, ekranlar) derlenmiştir.

## Uygulama hakkında

- **Sektör:** Okul ve ofis malzemeleri (defter, kalem, çanta/sumka, kitap vb.)
- **Para birimi:** TMT (Türkmen Manadı)
- **Diller:** Türkmence (`tk`, varsayılan) ve Rusça (`ru`) — uygulama içi tam çeviri desteği ile
- **API:** `https://atlas.com.tm/api`
- **Web sitesi:** `https://atlas.com.tm`
- **Android application ID:** `tm.com.atlas`

## Özellikler

- **Ana sayfa** — banner'lar, indirimli ürünler, yeni gelen ürünler, kategori kısayolları
- **Kategoriler & Markalar** — segment kontrollü sekme geçişiyle (iOS tarzı animasyon) kategori/marka listeleme, alt kategori ve markaya göre ürün filtreleme
- **Ürün detayı** — çoklu görsel carousel'i, favoriye ekleme, paylaşma, stok/artikul/barkod bilgisi, sepete ekleme
- **Sepet** — miktar artırma/azaltma, "sepete uçma" animasyonu ile görsel geri bildirim
- **Favoriler** — API destekli beğeni/beğenmeme (`products/like`, `products/unlike`), anlık senkronize liste
- **Arama** — canlı ürün arama
- **Sipariş & Ödeme** — sepetten checkout akışı, sipariş geçmişi (`my_orders`)
- **Kimlik doğrulama** — telefon numarası + OTP ile kayıt, giriş
- **Bildirimler** — Firebase Cloud Messaging + yerel bildirimler (arka planda da çalışır)
- **Profil** — kullanıcı hesabı, dil değiştirme

## Teknoloji yığını

| Katman | Kullanılan |
|---|---|
| Dil / Framework | Flutter (Dart, SDK ^3.6.0) |
| Durum yönetimi | [GetX](https://pub.dev/packages/get) (`get: ^4.7.2`) — controller, routing, i18n, reactive state |
| Backend iletişimi | `http` paketi, özel `CallApi` servisi |
| Bildirimler | `firebase_core`, `firebase_messaging`, `flutter_local_notifications` |
| Yerel depolama | `get_storage` (oturum/token, dil tercihi) |
| Görsel | `cached_network_image`, `flutter_svg`, `lottie`, `image_picker` |
| Diğer | `share_plus`, `url_launcher`, `flutter_inappwebview` |
| İkon seti | `hugeicons` |
| Yazı tipi | Gilroy (custom font) |

## Proje yapısı

```
lib/
├── core/
│   ├── lang/            # tk/ru çeviriler (GetX Translations)
│   ├── services/        # API client, auth storage, catalog service, FCM
│   ├── theme/           # renkler, tema
│   └── utils/
├── modules/
│   ├── auth/            # login, telefon+OTP kayıt
│   ├── home/             # ana sayfa
│   ├── category/         # kategori & marka listeleme
│   ├── brands/
│   ├── product_detail/   # ürün detay ekranı
│   ├── favorites/        # favoriler
│   ├── search/            # arama
│   ├── orders/            # sepet, checkout, sipariş geçmişi
│   ├── profile/
│   ├── main/              # bottom nav bar, ana Scaffold, paylaşılan controller'lar
│   └── splash/
└── widgets/               # ProductCard, AnimatedBottomNavBar, sepete uçma animasyonu vb. paylaşılan bileşenler
```

Her modül genelde `views/`, `controllers/`, `bindings/` (ve gerekirse `models/`) alt klasörlerine sahip — GetX'in standart modüler yapısı izleniyor.

## Kurulum

```bash
flutter pub get
flutter run
```

Firebase yapılandırması `lib/firebase_options.dart` içinde tanımlı (FlutterFire CLI ile üretilmiştir); yeni bir Firebase projesine bağlamak için `flutterfire configure` komutu tekrar çalıştırılmalı.
