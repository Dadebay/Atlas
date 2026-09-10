# Atlas — Native Hissiyat, Animasyon ve Performans Uygulama Planı

- **Durum:** KOD TARAFI TAMAMLANDI — cihazda profil ölçümü ve feel-check kaldı
- **Kod tabanı commit'i:** `141cb8f`
- **Hazırlanma tarihi:** 2026-09-10
- **Platform:** Flutter / Dart, GetX, iOS + Android
- **Amaç:** Uygulamanın mevcut davranışını ve görsel kimliğini koruyarak daha hızlı açılması, kaydırma ve geçişlerin akıcı olması, etkileşimlerin iOS ve Android'de doğal hissettirmesi.
- **Uygulayıcı için önemli not:** Çalışma ağacı bu plan hazırlanırken zaten değişiklikler içeriyordu. Kullanıcı değişikliklerini silme, geri alma veya topluca yeniden biçimlendirme. Her fazı ayrı ve küçük diff olarak uygula.

## 1. Başarı tanımı

Bu çalışma “her yere animasyon ekleme” işi değildir. Native his için üç şey birlikte sağlanmalıdır:

1. Dokunma ve durum değişimi anında algılanmalı.
2. Hareket, öğelerin ekrandaki mekânsal ilişkisini açıklamalı.
3. Animasyon açıkken 60 Hz cihazda frame bütçesi 16,67 ms'yi; 120 Hz cihazda 8,33 ms'yi aşmamalı.

Tamamlandığında:

- Uygulama yapay bir 2,8 saniyelik splash beklemesi yapmaz.
- Ana ekran mümkün olan en erken frame'de çizilir; ikincil servisler arka planda başlar.
- Kaydırma sırasında sürekli log, gereksiz layout ve görünmeyen sekmelerde çalışan ticker bulunmaz.
- Alt navigasyon, kategori segmenti, sepete ekleme, favori kaldırma ve açılır ayarlar hareket dili bakımından tutarlıdır.
- “Hareketi azalt” açıkken konum/ölçek hareketleri kaldırılır veya sade bir opacity geçişine düşer.
- iOS ve Android geri hareketi, route geçişi, ripple/press feedback ve haptic davranışı platform beklentisine uyar.

## 2. Önce ölç: değişiklik öncesi baseline

Kod değiştirmeden önce aşağıdaki ölçümleri fiziksel bir düşük/orta segment Android cihazda ve mümkünse 120 Hz iPhone'da al. Debug mod performans kararı için kullanılmamalı.

```bash
flutter analyze
flutter test
flutter run --profile
```

DevTools Performance ekranında aşağıdaki akışları ayrı ayrı kaydet:

1. Cold start → ilk kullanılabilir ana ekran.
2. Ana sayfayı en baştan en alta hızlı kaydırma; pagination tetikleme.
3. Alt sekmeler arasında 10 kez hızlı geçiş.
4. Ürün listesinde art arda üç ürünü sepete ekleme.
5. Kategori ↔ marka segmentinde hızlı geçiş.
6. Favorilerden art arda ürün kaldırma.
7. Ürün detayı → tam ekran galeri → pinch zoom → geri.

Kaydedilecek metrikler:

- İlk frame ve ilk kullanılabilir içerik zamanı.
- UI/Raster thread frame süreleri ve jank sayısı.
- Ana sayfa açıldıktan sonra bellek; 5 dakika gezinti sonrası bellek.
- Bir ürün grid'inde canlı `AnimationController`/ticker sayısı.
- Görünmeyen sekmelerde raster/UI aktivitesi.
- Her akış için ekran kaydı; değişiklik sonrası aynı hareketlerle karşılaştır.

Hedefler:

- Profile modda test edilen ana akışlarda frame'lerin en az %99'u cihazın frame bütçesinde.
- Alt navigasyon ve segment geçişinde layout kaynaklı sürekli frame işi olmaması.
- Cold start'ta sabit bekleme olmaması; ağ yavaş olsa dahi shell'in gösterilmesi.
- Aynı ekranı tekrar açarken ağ görsellerinde görünür yeniden yükleme/flicker olmaması.

## 3. Ortak motion sistemi — önce bunu oluştur

Yeni dependency ekleme. Flutter'ın `Curves`, `Cubic`, implicit animation widget'ları ve gerektiğinde `AnimationController` yeterli.

### Yeni dosya

`lib/core/theme/app_motion.dart`

```dart
import 'package:flutter/material.dart';

abstract final class AppMotion {
  // Küçük press/renk geri bildirimi.
  static const Duration instant = Duration(milliseconds: 120);
  // Küçük popover, icon ve switch değişimleri.
  static const Duration fast = Duration(milliseconds: 160);
  // Standart UI giriş/çıkışları.
  static const Duration standard = Duration(milliseconds: 220);
  // Modal/sheet gibi seyrek ve büyük yüzeyler.
  static const Duration emphasized = Duration(milliseconds: 300);

  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(
    BuildContext context,
    Duration normal,
  ) => reduceMotion(context) ? Duration.zero : normal;
}
```

Uygulayıcı mevcut Flutter sürümünde `MediaQueryData.disableAnimations` API'sini `flutter analyze` ile doğrulamalı. API yoksa aynı anlamı `WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations` ile tek bir helper içinde sağlamalı; her widget'a farklı çözüm yazmamalı.

### Hareket kuralları

- Giriş/çıkış: `AppMotion.easeOut`.
- Ekran üstünde bir yerden başka yere hareket: `AppMotion.easeInOut`.
- Bottom sheet: `AppMotion.drawer`.
- Basma geri bildirimi: 120–160 ms, ölçek en fazla `0.97`.
- UI animasyonu normalde 300 ms altında kalmalı.
- Hiçbir öğe `scale: 0` ile görünmemeli; minimum başlangıç ölçeği `0.92–0.97`.
- Kaydırma sırasında `width`, `height`, `left`, `top` veya padding animasyonu çalıştırma. `Transform`, `SlideTransition` ve `Opacity/FadeTransition` tercih et.
- Alt sekme geçişinde sayfa içeriğini kaydırma/fade etme. Sık kullanılan tab değişiminde içerik anında değişmeli; yalnız seçim göstergesi kısa hareket edebilir.
- Aynı aksiyonda birden fazla gösterişli animasyon bindirme. Sepete eklemede press + uçuş + snackbar + badge bounce şu anda aynı anda çalışıyor; bunu tek bir okunaklı koreografiye indir.

## 4. Denetim özeti ve öncelik

| # | Öncelik | Kategori | Konum | Bulgu | Hedef |
|---|---|---|---|---|---|
| 1 | P0 | Açılış | `lib/main.dart:53-112`, `lib/modules/splash/views/splash_screen.dart:30-72` | `runApp` öncesi servis bekleniyor; splash ayrıca sabit 2800 ms bekliyor. | İlk frame'i öne al, gerçek bootstrap durumu kullan, sabit beklemeyi kaldır. |
| 2 | P0 | Scroll/render | `lib/modules/home/views/home_screen.dart:78-286` | `SingleChildScrollView` içinde shrink-wrap grid'ler tüm ürünleri layout eder. | Tek `CustomScrollView` + sliver mimarisi. |
| 3 | P0 | Runtime | `lib/modules/home/controllers/home_controller.dart:46-56, 92-190, 203-243` | Scroll'un her frame'inde ve büyük API body/ürün döngülerinde `print` çalışıyor. | Release/profile'da sıfır hot-path logging. |
| 4 | P0 | Animasyon performansı | `lib/widgets/animated_bottom_nav_bar.dart:80-92` | `AnimatedPositioned.left` 420 ms boyunca layout; üstüne pill ve icon bounce ekleniyor. | Transform tabanlı 220 ms gösterge; bounce azalt. |
| 5 | P0 | Yaşam döngüsü | `lib/modules/main/views/main_screen.dart:20-29` | `IndexedStack` tüm sekmeleri canlı tutuyor; görünmeyen sekmelerde Lottie/shimmer/ticker çalışabilir. | Her child için `TickerMode`; seçili olmayan sekmede ticker kapalı. |
| 6 | P1 | Liste maliyeti | `lib/widgets/product_card.dart:56-83` | Her `ProductCard` kendi `AnimationController`'ını kuruyor. Uzun gridlerde yüzlerce controller oluşabilir. | Controller'ı karttan çıkar; yalnız etkileşim anında implicit hareket. |
| 7 | P1 | Fizik/maliyet | `lib/widgets/cart_fly_animation.dart:105-138` | 650 ms `easeIn`, her frame `Positioned.left/top`; tepki yavaş ve layout maliyetli. | 380–420 ms transform tabanlı uçuş, `easeInOut`, reduced motion alternatifi. |
| 8 | P1 | Sıklık/fizik | `lib/widgets/animated_bottom_nav_bar.dart:121-232` | 320/380 ms back/elastic; badge `scale(0)` ile geliyor. Sık etkileşim için fazla oyuncaklı. | 120–220 ms, küçük scale, badge `0.92→1`. |
| 9 | P1 | Durum geçişi | `lib/widgets/product_card.dart:350-360`, `lib/modules/product_detail/views/product_detail_screen.dart:627-647` | Buton ↔ stepper tam `ScaleTransition` ile sıfırdan büyüyor. | Fade + `0.96→1` scale, 160–200 ms; boyut sabit kalsın. |
| 10 | P1 | Favoriler | `lib/modules/favorites/views/favorites_screen.dart:24-58, 120-151` | Kart başına controller map'i büyüyor; 320 ms `easeIn` sonucu geciktiriyor. | 160–180 ms ease-out çıkış; controller temizliği; optimistic rollback. |
| 11 | P1 | Erişilebilirlik | proje geneli | Reduced motion, Semantics ve haptic politikası yok. | Merkezi policy ve kritik kontrollere semantics. |
| 12 | P2 | Tutarlılık | `lib/main.dart:131` ve çeşitli `Get.to(... transition:)` çağrıları | Android dahil tüm platformlarda global Cupertino; bazı sayfalar ayrıca sağdan/fade geçiyor. | Platform-native route politikası ve istisna listesi. |
| 13 | P2 | Skeleton | `lib/widgets/product_card_shimmer.dart:13-67, 275-319, 345-393`; `lib/modules/category/views/category_screen.dart:901+` | Her skeleton kendi tekrar eden controller'ına ve geniş ShaderMask rebuild'ine sahip. | Tek ticker sahibi, repaint sınırı, TickerMode/reduced motion. |
| 14 | P2 | Görsel cache | `lib/widgets/app_dialogs.dart:394`, `lib/modules/home/widgets/home_widgets.dart:243`, `lib/widgets/full_screen_image_viewer.dart:126` | Üç alanda ham `Image.network` kullanılıyor. | `CachedNetworkImage` + decode boyutu + tutarlı placeholder. |

## 5. Faz 1 — Açılışı gerçekten hızlı yap (P0)

### Mevcut problem

`lib/main.dart:53-112` içinde aşağıdakiler `runApp` çağrısından önce bekleniyor:

```dart
await GetStorage.init();
await localNotificationsService.init();
await Firebase.initializeApp(...);
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(...);
await firebaseMessagingService.init(...);
runApp(const AtlasApp());
```

Ardından `lib/modules/splash/views/splash_screen.dart:49-72` gerçek iş bitmiş olsa bile bekliyor:

```dart
await Future.delayed(const Duration(milliseconds: 2800));
final result = await InternetAddress.lookup('atlas.com.tm')
    .timeout(const Duration(seconds: 5));
Get.offAll(() => const MainScreen(), binding: MainBinding());
```

Bu, en kötü durumda kullanıcıya 7–8 saniyelik sahte bir açılış verebilir. Ayrıca yüzde göstergesi gerçek ilerlemeye bağlı değildir.

### Uygulama

1. `WidgetsFlutterBinding.ensureInitialized()` ve dil/oturum için gerçekten gerekli olan küçük local storage hazırlığı dışında `runApp`'i bloke etme.
2. `AtlasApp` altında bir `BootstrapGate` oluştur. Shell ilk frame'de çizilsin; Firebase, local notification ve FCM hazırlığı gate tarafından idempotent olarak yürütülsün.
3. Uygulamanın ana alışveriş içeriğini Firebase hazır olmamasına bağlama. Firebase/FCM başarısızlığı non-fatal kalmalı.
4. DNS lookup ile uygulamanın tümünü “internet yok” ekranına kilitleme. Ana ekran açılsın; gerçek API isteğinin network hatası ekran içinde retry state'i üretsin. Mutlaka health-check kalacaksa 1200–1500 ms timeout ve cached son durum kullan; açılışı sabit süre bekletme.
5. Splash'taki yüzde ve 2500 ms animation controller'ı kaldır. Native launch screen → kısa logo crossfade (`160–220 ms`) → shell geçişi yeterli.
6. Notification iznini cold start'ta otomatik isteme. Kullanıcı faydayı gördükten sonra, bağlamlı bir ekranda iste. Bu hem native UX hem dönüşüm için daha doğrudur.
7. Bootstrap iki kez çağrılsa bile servislerin iki defa initialize olmamasını test et.

### Sınırlar

- FCM background handler anotasyonunu ve background initialization zorunluluklarını bozma.
- Auth token doğrulamasını kaldırma; yalnız ilk frame'i gereksiz yere bloklamayacak şekilde ayır.
- Başarısız servis init'ini sessizce sonsuza kadar retry eden loop ekleme.

### Kabul testi

- Airplane mode'da uygulama 2,8 saniye boş beklemeden kullanılabilir bir offline/error shell gösterir.
- Firebase konfigürasyonu bozuk test build'inde katalog ekranı yine açılır.
- Cold start ekran kaydında sahte yüzde bulunmaz.
- Bildirim izni uygulama logosunun üstünde değil, bağlamlı istem anında görünür.

## 6. Faz 2 — Ana sayfayı tek scroll ve lazy sliver yapısına geçir (P0)

Bu konu için mevcut `SCROLL_INCELEME_NOTLARI.md` dosyasındaki kararları koru. Tercih edilen çözüm zaten `CustomScrollView`/sliver olarak belgelenmiş; alternatif `primary: false` yaması nihai çözüm değildir.

### Uygulama

`lib/modules/home/views/home_screen.dart`:

1. `RefreshIndicator > SingleChildScrollView > Column` yapısını `RefreshIndicator > CustomScrollView` yap.
2. Banner, section başlıkları ve yatay listeleri `SliverToBoxAdapter` ile ekle.
3. Kategori ve ürün grid'lerini `SliverGrid`/`SliverPadding` yap. `shrinkWrap: true` grid bırakma.
4. “Tüm ürünler” pagination loader'ını ayrı `SliverToBoxAdapter` yap.
5. `ScrollController` yalnız ana `CustomScrollView` üzerinde kalsın.
6. Yatay `ListView.builder` öğelerinde `primary: false` kalsın.
7. Loading görünümünü sliver uyumlu hale getir: `ProductCardShimmerGrid` için `SliverProductCardShimmerGrid` varyantı ekle veya delegate'i ortaklaştır.
8. `HomeScreen.build` içindeki `Get.put(BrandsController())` kaydını (`home_screen.dart:32`) binding/controller yaşam döngüsüne taşı. `build` içinde dependency oluşturma.

### Neden

Mevcut `GridView.builder(shrinkWrap: true)` bütün grid yüksekliğini hesaplamak zorunda olduğu için lazy rendering avantajı kaybolur. Pagination büyüdükçe layout maliyeti ve bellek artar. Tek sliver viewport yalnız görünür ve cache alanındaki kartları oluşturur.

### Kabul testi

- Loading, dolu, boş, refresh ve pagination durumlarının hepsinde tek dikey scrollable bulunur.
- Ana sayfada 100+ ürün yüklendiğinde widget sayısı ürün sayısıyla doğrusal biçimde ekranda tutulmaz.
- Profil → login → ana sayfa dönüşü sonrası scroll ilk swipe'ta çalışır.
- Tab değiştirip geri gelince scroll konumu korunur.

## 7. Faz 3 — Hot-path logları ve gereksiz işi kaldır (P0)

### Uygulama

1. `lib/modules/home/controllers/home_controller.dart:46-56` içindeki her scroll event'inde çalışan `print` bloğunu tamamen kaldır.
2. Aynı dosyada response body ve ürün başına logları (`92-190`, `219`) kaldır veya yalnız `kDebugMode` + özet log ile sınırla. Response body/token/kişisel veri loglama.
3. Proje genelinde `print`/`debugPrint` taraması yap. Frame, scroll, itemBuilder, map/sort döngüsü ve build içindeki loglar release/profile yolunda çalışmamalı.
4. `_onScroll` pagination eşiğinin aynı frame'lerde tekrar çağrılmasını mevcut `isLoadingMoreAll` guard'ıyla koru; gerekmedikçe debounce ekleme.
5. Büyük JSON parse'ın profile ölçümünde UI thread'i aştığı kanıtlanırsa yalnız o endpoint için `Isolate.run`/`compute` kullan. Ölçüm olmadan bütün parse katmanını isolate'a taşıma.

### Kabul testi

- Profile çalıştırmada hızlı scroll sırasında konsola satır yağmaz.
- Pagination yalnız bir sonraki sayfa için tek request üretir.
- DevTools CPU flame chart'ta logging görünmez.

## 8. Faz 4 — Alt navigasyonu compositor dostu ve sakin yap (P0)

### Mevcut problem

`lib/widgets/animated_bottom_nav_bar.dart:80-92`:

```dart
AnimatedPositioned(
  duration: const Duration(milliseconds: 420),
  curve: Curves.easeOutBack,
  left: itemWidth * currentIndex,
  child: _Pill(key: ValueKey(currentIndex)),
)
```

Her seçimde `left` layout'u animasyon boyunca değişir. `_Pill` ayrıca 320 ms `easeOutBack`, icon 380 ms `elasticOut`, badge ise `scale 0→1` çalıştırır. Çok sık kullanılan bir kontrolde üç bounce üst üste gelir.

### Hedef

1. Pill'i sabit `left: 0`, sabit `width: itemWidth` ile konumlandır.
2. Yatay hareketi `TweenAnimationBuilder<double>` veya controller + `Transform.translate` ile yap. Hedef offset `itemWidth * currentIndex`.
3. Süre `220 ms`, curve `AppMotion.easeInOut`.
4. Pill için index'e bağlı `ValueKey` ve her inişte yeniden başlayan pop animasyonunu kaldır.
5. Aktif icon sadece renk değişimi + en fazla `0.96→1.0`, `140 ms`, `AppMotion.easeOut` kullansın. `elasticOut` kullanma.
6. Badge ilk görünüşte `0.92→1`, `160 ms`; sayı değişiminde yalnız kısa crossfade veya `AnimatedSwitcher` kullan. `scale 0` kullanma.
7. Sekme seçiminde `HapticFeedback.selectionClick()` yalnız index gerçekten değiştiğinde çalışsın. Reduced motion açıkken haptic kalabilir.
8. Aynı sekmeye tekrar basınca animasyonu başlatma. İleride “scroll to top” davranışı eklenirse ayrı görev olsun.

### TickerMode

`lib/modules/main/views/main_screen.dart:20-29` içindeki her IndexedStack child'ını şu davranışla sar:

```dart
TickerMode(
  enabled: controller.currentIndex.value == index,
  child: const HomeScreen(),
)
```

Tüm beş child için uygula. Widget'ları yeniden yaratacak key ekleme; state ve scroll pozisyonu korunmalı.

### Kabul testi

- Performance overlay'de sekme göstergesi sırasında layout spike oluşmaz.
- 10 hızlı tab tıklamasında gösterge mevcut konumundan yeni hedefe retarget olur; başa zıplamaz.
- Seçili olmayan Favorites/Home içindeki Lottie veya shimmer tick etmez.
- Android ve iOS'ta bottom safe area yüksekliği korunur.

## 9. Faz 5 — Ürün kartı ve sepete ekleme koreografisi (P1)

### ProductCard controller maliyeti

`lib/widgets/product_card.dart:56-83` her kart için 220 ms'lik `_addAnim` controller'ı oluşturuyor. Bunu kart seviyesinden kaldır.

Hedef davranış:

1. Kart yüzeyine genel scale animasyonu verme; liste kaydırılırken yanlış press algısı yaratmamalı.
2. Favori ve sepete ekle butonunda `InkWell`/`InkResponse` veya küçük ortak bir pressable kullan. `onTapDown` sırasında `0.97`, `onTapUp/onTapCancel` ile `1.0`, `120 ms`.
3. Buton → stepper geçişinde `AnimatedSwitcher`, `160 ms`, `AppMotion.easeOut` kullan. Transition `FadeTransition` + `Tween(begin: 0.96, end: 1.0)` scale olsun.
4. `layoutBuilder` ile eski/yeni child'ın kart yüksekliğini değiştirmemesini garanti et. Stepper ve buton alanı aynı 36 px kutuda kalmalı.
5. Aynı pattern'i `lib/modules/product_detail/views/product_detail_screen.dart:627-647` için 52 px kutuda kullan.
6. Miktar değişiminde tüm stepper'ı yeniden scale etme. Yalnız sayıyı `AnimatedSwitcher` ile 120–160 ms dikey `0.15` offset + fade yap; hızlı tıklamada retarget edilebilir olsun.
7. Favori icon değişiminde kalp `0.92→1.0`, 160 ms ve renk crossfade kullanabilir. Her toggle'da Lottie çalıştırma.

### Sepete uçuş

`lib/widgets/cart_fly_animation.dart`:

1. Süreyi `650 ms` yerine `400 ms` yap.
2. `Curves.easeInCubic` yerine `AppMotion.easeInOut` kullan.
3. Overlay entry'yi başlangıçta sabit konumlandır; her frame `left/top` değiştirme. Hareketi `Transform.translate` ile uygula.
4. Arc hesabı korunabilir fakat sabit `130` yerine başlangıç-bitiş mesafesine göre clamp edilmiş bir yay kullan: `min(distance * 0.22, 96.0)`. Çok kısa uçuşta gereksiz yüksek yay olmasın.
5. Scale `1.0→0.35`; opacity yalnız son %20'de `1→0`.
6. Hareket bittiğinde cart icon/badge en fazla `0.94→1`, 140 ms pulse yapabilir. Başka bounce ekleme.
7. Reduced motion açıkken uçan görsel oluşturma. Sepet badge/count anında güncellensin; kısa renk/opacity feedback ve `HapticFeedback.lightImpact()` yeterli.
8. Kullanıcı üç kez hızlı eklerse OverlayEntry'lerin güvenle tamamlanıp kaldırıldığını widget test veya debug assertion ile doğrula.

### Snackbar

Ürün kartı şu anda uçuşun yanında 2 saniyelik snackbar da açıyor ve yenisi gelince öncekini kapatıyor (`product_card.dart:116-172`). Badge ve stepper zaten başarıyı anlatıyorsa snackbar'ı yalnız hata/geri alma aksiyonu için kullan. Başarı snackbar'ı kalacaksa:

- Uçuş ile aynı anda gösterişli giriş yapmasın.
- 200–220 ms ease-out giriş, 160 ms çıkış.
- Arka arkaya eklemelerde kuyruğa dizilmesin; metni/count'u güncellesin.

### Kabul testi

- 50+ kartlı listede kart başına özel `AnimationController` yoktur.
- Sepete ekleme anında state optimistic değişir; animasyon API cevabını beklemez.
- API başarısız olursa state geri alınır ve kullanıcıya hata görünür.
- Uçuş sırasında UI/Raster frame bütçesi aşılmaz.

## 10. Faz 6 — Kategori/marka, arama ve bottom sheet (P1)

`lib/modules/category/views/category_screen.dart` içindeki mevcut segment fikri doğrudur; süre ve fizik sadeleştirilmeli.

### Segment

1. `AnimatedPositioned.left` (`292-310`) yerine sabit konum + `Transform.translate` kullan.
2. Süre `200–220 ms`, curve `AppMotion.easeInOut`.
3. İçerik `AnimatedSwitcher` süresi `220 ms` olsun. Gelen panel yönü açıklayan en fazla ekran genişliğinin %8'i kadar slide + fade kullansın; mevcut `%25` hareketi azalt.
4. Çıkan panelde `Curves.easeInCubic` kullanma. Çıkış da hızlı başlayan `AppMotion.easeOut` olsun.
5. Kullanıcı geçiş bitmeden tekrar sekmeye dokunursa mevcut konumdan yeni hedefe dönmeli; yeni keyframe sıfırdan başlamamalı.
6. Reduced motion açıkken içerik sadece 120–160 ms fade veya anlık swap yapsın; yatay hareket olmasın.
7. Segment değişiminde `HapticFeedback.selectionClick()` bir kez çalışsın.

### Search alanı

`AnimatedSize` ile TextField açmak layout değiştirir fakat bu seyrek ve açıklayıcı bir geçiştir; kaldırma. Süreyi `220 ms` tut, curve'i `AppMotion.easeOut` yap. Reduced motion'da süre sıfır olsun. Focus request animasyon tamamını beklememeli; ilk 1–2 frame sonrası güvenli focus yeterlidir.

### Bottom sheet

`category_screen.dart:804-888` içindeki sheet'e:

- `isDismissible: true`, `enableDrag: true`, safe area ve klavye inset davranışını açıkça ver.
- GetX sürümü destekliyorsa `enterBottomSheetDuration: 300 ms`, `exitBottomSheetDuration: 220 ms`, `curve: AppMotion.drawer` karşılığını kullan.
- Desteklemiyorsa API'yi zorlamadan mevcut route'u koru; dependency güncelleme bu işin parçası değildir.
- Sheet içindeki drag handle semantik olarak dekoratif olmalı; close butonu en az 44×44 hit area ve tooltip/semantic label almalı.

### Kabul testi

- Hızlı category↔brand tıklaması içerik çift görünmesine veya sıçramaya yol açmaz.
- Klavye açılırken search alanı overflow üretmez.
- Sheet Android back ve iOS swipe/drag ile doğal kapanır.

## 11. Faz 7 — Favorilerden kaldırma (P1)

Mevcut uygulama `Map<String, AnimationController>` tutuyor, 320 ms `easeIn` çıkışı tamamlandıktan sonra local state'i güncelliyor (`favorites_screen.dart:24-58, 120-151`).

### Uygulama

1. Çıkışı `160–180 ms`, `AppMotion.easeOut`, scale `1→0.96` + opacity `1→0` yap.
2. Controller map'i korunursa animasyon bitince ilgili controller'ı `dispose()` edip map'ten sil. Liste refresh olduğunda artık görünmeyen id'leri de temizle.
3. Tercihen controller map'i yerine ürün id'si bazlı “removingIds” state + implicit animation kullan; ancak GridView item'ı state kaldırıldığında çıkış yapabilmek için süre boyunca model görünür kalmalı.
4. API çağrısı kullanıcı feedback'ini bloklamasın. Görsel kaldırma kısa sürede tamamlandıktan sonra optimistic list update yap; başarısızlıkta öğeyi eski indeksine geri koy ve kısa fade-in göster.
5. Reduced motion'da kart anında kaldırılsın; rollback olursa fade yeterli.
6. Empty state'e geçiş `AnimatedSwitcher` ile 180–220 ms fade olabilir. Sonsuz tekrarlayan Lottie yerine bir kez oynat veya TickerMode/reduced motion ile durdur.

### Kabul testi

- 30 farklı ürün kaldırıldıktan sonra controller map'i büyümeye devam etmez.
- Hızlı iki kaldırma doğru ürünleri etkiler.
- API hatasında ürün deterministik şekilde eski konumuna döner.

## 12. Faz 8 — Skeleton, Lottie ve görünmeyen animasyonlar (P2)

### Skeleton

`product_card_shimmer.dart` içinde kategori, yatay liste ve grid ayrı 1100 ms controller çalıştırıyor. Kategori ekranında ayrıca lokal `BrandShimmer` var.

1. Ortak `ShimmerScope`/`Shimmer` widget'ı oluştur; aynı görünür ekran içindeki skeleton'lar tek animation value paylaşsın.
2. Gradient'i mümkün olduğunca bir dış `ShaderMask` altında uygula; her frame tüm widget ağacını yeniden kurma. Statik child'ı `AnimatedBuilder.child` parametresiyle dışarı al.
3. Shimmer repaint alanını `RepaintBoundary` ile sınırla; boundary sayısını ölçmeden her küçük kutuya ayrı boundary koyma.
4. `TickerMode.of(context)` kapalıyken controller çalışmamalı. Controller framework tarafından mute edilse bile ağ/yeniden build olmadığını ölç.
5. Reduced motion açıkken hareketli gradient yerine sabit gri skeleton göster.
6. Loading 400 ms'den kısa sürüyorsa skeleton flash'ını önlemek için gecikmeli gösterim değerlendir: içerik 150–200 ms içinde gelirse skeleton hiç görünmesin. Bunu yalnız ölçüm ve UX testi sonrası uygula.

### Lottie

- `ProductCard` image placeholder'ında her kart için Lottie (`product_card.dart:500-511`) pahalıdır. Bunu statik düşük maliyetli placeholder veya tek dönen progress indicator ile değiştir. Liste içindeki her görsel hücresinde ayrı Lottie çalıştırma.
- Empty state Lottie'leri sürekli tekrar etmemeli; bir kez oynatıp son frame'de durmalı.
- Asset JSON boyutlarını kontrol et. Görünür alandan çok büyük composition kullanma.

### Kabul testi

- Home loading'de aynı anda yalnız bir shimmer ticker vardır.
- Tab görünmezken hiçbir Lottie/shimmer ilerlemez.
- Reduced motion açıkken skeleton sabittir.

## 13. Faz 9 — Route, dialog ve tam ekran galeri native davranışı (P2)

### Route politikası

`lib/main.dart:131` şu anda her platforma `Transition.cupertino` zorluyor. Ayrıca bazı sayfalar `Transition.rightToLeft` veya `Transition.fadeIn` kullanıyor.

1. GetX sürümünde mevcutsa global `Transition.native` kullan. Yoksa `GetPage`/özel page route ile platforma göre:
   - iOS/macOS: `CupertinoPageRoute` hissi ve interactive back gesture.
   - Android: Material 3 platform transition.
2. Normal detail/settings sayfalarında özel `transition:` parametrelerini kaldır; global platform policy'ye bırak.
3. Yalnız tam ekran fotoğraf galerisi fade/hero istisnası olabilir.
4. Auth step'lerinde ileri/geri yönü korunmalı; ancak aynı route policy üzerinden tanımlanmalı.
5. Route süresini keyfi biçimde uzatma; framework platform default'u tercih edilir.

### Dialog ve sheet

- `Get.dialog` kullanan login/quick-order dialoglarında barrier dismiss, back davranışı ve focus traversal test edilmeli.
- Dialog scale başlangıcı en az `0.96`, opacity `0→1`, 200–220 ms ease-out. `scale 0` yok.
- Kritik onaylarda butonlar native sıraya ve platform davranışına göre gözden geçirilsin; fakat metin/iş mantığı değiştirilmesin.

### Galeri

- Mevcut ürün carousel → tam ekran Hero ilişkisi korunmalı.
- Tam ekran galeride görüntü zoom'lanmışken yatay `PageView` ile gesture yarışını cihazda test et. Zoom > 1 iken önce pan; scale 1'e dönünce page swipe davranışı hedeflenir.
- Close butonu `GestureDetector` yerine en az 44×44 hit area'lı `IconButton`/`InkResponse`, semantic label ve tooltip kullansın.
- İsteğe bağlı “swipe down to dismiss” ancak ayrı bir controller/gesture çatışması yaratmadan, gerçek cihaz testiyle eklenebilir. Bu planın zorunlu parçası değildir.

## 14. Faz 10 — Görsel, rebuild ve bellek optimizasyonu (P2)

### Görseller

1. Aşağıdaki ham ağ görsellerini `CachedNetworkImage` ile değiştir:
   - `lib/widgets/app_dialogs.dart:394`
   - `lib/modules/home/widgets/home_widgets.dart:243`
   - `lib/widgets/full_screen_image_viewer.dart:126`
2. Gösterim ölçüsü bilinen tüm görsellerde `memCacheWidth`/`memCacheHeight` değerini logical size × DPR olarak ver. Orijinal dev görseli küçük karta decode etme.
3. Aynı URL için placeholder ve error state tutarlı olsun; loading sırasında layout boyutu değişmesin.
4. Çok büyük tam ekran görsellerde kalite ihtiyacını koru; thumbnail cache boyutunu full-screen cache'e zorla uygulama.
5. Sonraki carousel görseli için yalnız bir komşu sayfayı `precacheImage` ile hazırla. Bütün galeriyi aynı anda decode etme.

### Rebuild sınırları

1. `Obx` builder'ların tam olarak hangi Rx değerlerini okuduğunu denetle. Büyük Scaffold/Column yerine mümkün olan en küçük değişen subtree'yi sar.
2. `ProductCard` içindeki cart ve favorite `Obx` alanları ayrı kalabilir; ancak her cart miktar değişiminde tüm görünür kartların `_cartIndex` taraması yapıp yapmadığını profile et.
3. Gerekirse `CartController` içinde id→quantity map/Rx selector oluştur. Bu ancak ölçümde tüm kart rebuild'i kanıtlanırsa uygulanmalı.
4. `const` yapılabilen statik widget'ları const yap; fakat bunun için 1000 satırlık dosyalarda anlamsız toplu churn üretme.
5. `RepaintBoundary` yalnız pahalı bağımsız animasyon/görseller çevresinde kullanılmalı. Çok fazla boundary GPU belleğini artırabilir.

### Büyük dosyalar

`category_screen.dart` (~1000 satır), `product_detail_screen.dart` (~975), `home_screen.dart` (~573) ve `product_card.dart` (~513) okunabilirlik ve rebuild sınırı açısından bileşenlere ayrılabilir. Bu bir performans garantisi değildir. Önce Faz 1–9 ölçümlerini tamamla; sonra yalnız bağımsız rebuild/lifecycle sahibi parçaları çıkar. Salt satır sayısı için refactor yapma.

## 15. Native dokunma, semantics ve haptics politikası

Proje taramasında `Semantics`, `HapticFeedback` ve reduced-motion kullanımı bulunmadı.

### Dokunma

- Materyal yüzeylerinde çıplak `GestureDetector + Container` yerine `Material + InkWell/InkResponse` kullan. Bu ripple, focus, hover ve accessibility davranışını ücretsiz verir.
- iOS'ta her şeyi Cupertino widget'a çevirmek zorunlu değildir. Platform doğal hissi tutarlı hit target, hızlı feedback, doğru back gesture ve physics ile sağlanabilir.
- Tüm icon-only butonların minimum hit alanı 44×44 (iOS) / 48×48 (Material önerisi) olsun.
- Press scale yalnız temel feedback eksikse eklenmeli. Ripple + scale + haptic'i her butonda aynı anda kullanma.

### Haptics

- Bottom nav ve kategori segmenti: `selectionClick`.
- Sepete başarıyla ekleme: bir kez `lightImpact`.
- Hata, her increment/decrement, scroll veya sayfa açılışında haptic verme.
- Aynı kullanıcı aksiyonu controller ve widget tarafından iki kez haptic üretmemeli.

### Semantics

En az şu kontrollere label/state ekle:

- Bottom nav item: label, selected state, cart badge count.
- Favori: “favorilere ekle/çıkar” ve toggled state.
- Sepet arttır/azalt: ürün adı + yeni miktar.
- Carousel: “görsel X / Y”.
- Sadece icon olan close/back/filter/search kontrolleri.
- Loading indicator ve empty/error state.

### Reduced motion

Test cihazında Android “Remove animations” ve iOS “Reduce Motion” açılarak doğrula:

- Route ve büyük pozisyon hareketleri framework/platform politikasına düşer.
- Cart fly çalışmaz.
- Segment içerik slide'ı kaldırılır.
- Shimmer sabit placeholder olur.
- Opacity/renk gibi anlam taşıyan kısa feedback korunabilir.

## 16. Eklenmesi değerli animasyon fırsatları

Bunlar düzeltmeler tamamlandıktan sonra yapılmalı. Önce P0/P1 işlerini bitirmeden dekoratif motion ekleme.

### A. Miktar sayacı değişimi — yüksek değer, düşük maliyet

Konumlar:

- `lib/widgets/product_card.dart:396-409`
- `lib/modules/product_detail/views/product_detail_screen.dart:720-727`
- Sepet satırındaki quantity text alanı

Hedef: eski sayı yukarı `0→-0.15` ve fade-out, yeni sayı aşağıdan `0.15→0` ve fade-in; `120–160 ms`, `AppMotion.easeOut`. `AnimatedSwitcher` key'i quantity olmalı. Reduced motion'da yalnız kısa fade.

### B. Filtre/sort chip seçimi — durumun nerede değiştiğini anlatır

Konumlar:

- `product_list_screen.dart`
- `sub_category_product_screen.dart`
- `brand_product_screen.dart`

Hedef: background/border/text rengi `160 ms`; check/close icon `0.94→1`; liste sonuçları geldiğinde bütün grid'i uçurma. Network beklerken chip üzerinde küçük progress veya mevcut loading state yeterli.

### C. Empty → dolu / loading → içerik

Favorites, search, order ve katalog ekranlarında state teleport ediyor. Üst seviyede `AnimatedSwitcher` ile `180–220 ms` fade kullanılabilir. Büyük grid'e stagger verme; her refresh'te kartların sırayla gelmesi sık kullanımı yavaş ve yorucu yapar.

### D. Sipariş başarı anı — nadir ve anlamlı

Checkout gerçekten başarıyla tamamlandığında tek seferlik 400–700 ms Lottie/scale-fade kutlaması kullanılabilir. Bu nadir bir “delight” anıdır. Animasyon yalnız backend success sonrasında, bir kez çalışmalı; reduced motion'da static success icon + fade göstermeli.

### E. Pull-to-refresh durumu

Mevcut platform `RefreshIndicator` davranışını koru. Marka logolu özel loader ancak ölçüm ve kullanıcı testiyle; scroll physics veya overscroll davranışını bozacak custom gesture yazma.

## 17. Özellikle animasyon eklenmemesi gereken yerler

- Her bottom tab içerik değişiminde sayfa slide/fade.
- Ürün grid'i her açıldığında bütün kartlara stagger.
- Scroll sırasında app bar, ürün kartı veya fiyatın sürekli scale olması.
- Her plus/minus dokunuşunda bütün kartın zıplaması.
- Arama yazarken her sonuç kartının tekrar giriş animasyonu.
- Network beklemesini saklamak için uzun yapay progress.
- Normal back navigation üstüne custom fade + slide kombinasyonu.

## 18. Uygulama sırası ve bağımlılıklar

| Sıra | İş | Bağımlılık | Risk | Bitti |
|---|---|---|---|---|
| 1 | Baseline profil ve ekran kayıtları | Yok | Düşük | [ ] Cihaz gerektirir — kullanıcıda |
| 2 | `AppMotion` token/policy | Baseline | Düşük | [x] Tamamlandı — `lib/core/theme/app_motion.dart` |
| 3 | Hot-path log temizliği | Baseline | Düşük | [x] Tamamlandı — `lib/core/utils/app_log.dart`, proje geneli `print` taraması |
| 4 | Startup/bootstrap ve sahte splash kaldırma | Baseline | Yüksek | [x] Tamamlandı — `AppBootstrap`, `BootstrapGate`, `PushRegistration`; sabit 2800 ms + DNS kilidi + sahte yüzde kaldırıldı. Kilidin yerine plan §5.4'ün istediği ekran içi retry state'i geldi: `ConnectionErrorView` + `HomeController.showConnectionError`; `NoInternetScreen` de aynı tasarımı kullanıyor. |
| 5 | Home `CustomScrollView`/sliver dönüşümü | Baseline | Yüksek | [x] Tamamlandı — tek `CustomScrollView`, gerçek `SliverGrid`, `SliverProductCardShimmerGrid`, `BrandsController` binding'e taşındı |
| 6 | `TickerMode` ve bottom nav transform | AppMotion | Orta | [x] Tamamlandı — pill `Transform.translate` 220 ms, elastic/back eğriler kaldırıldı, aynı sekmeye basmak no-op, `selectionClick`, her tab `TickerMode` |
| 7 | ProductCard controller azaltma + switcher | AppMotion | Orta | [x] Tamamlandı — kart başına `AnimationController` kaldırıldı, ortak `Pressable`, 160 ms fade+0.96 switcher, `AnimatedQuantityText`, başarı snackbar'ı kaldırıldı |
| 8 | Cart fly compositor dönüşümü | 6–7 | Orta | [x] Tamamlandı — 400 ms `easeInOut`, `Transform.translate`, mesafeye göre yay, reduced motion'da uçuş yok, OverlayEntry tek seferlik temizlik |
| 9 | Kategori segment/search/sheet | AppMotion | Orta | [x] Tamamlandı — segment `Transform.translate` 220 ms, panel slide %25→%8, reduced motion fade, focus tek frame, sheet dismiss/drag + 44x44 close |
| 10 | Favori removal lifecycle | AppMotion | Orta | [x] Tamamlandı — controller map'i `removingIds` set'ine indirildi, 160 ms ease-out çıkış, reduced motion'da anında, hata rollback eski indekse |
| 11 | Skeleton/Lottie tek ticker | TickerMode | Orta | [x] Tamamlandı — `ShimmerScope`/`Shimmer` (kullanıldığında tick eden tek controller), tek dış `ShaderMask`, reduced motion'da sabit gri, `BrandShimmer` ortaklaştırıldı, kart Lottie placeholder'ı kaldırıldı, empty-state Lottie'leri tek sefer |
| 12 | Route/native transition politikası | AppMotion | Orta | [x] Tamamlandı — global `Transition.native`, sayfa başına `transition:` override'ları kaldırıldı (istisna: tam ekran galeri fade), dialog geçişleri token'lardan, galeri close/share/download 44x44 + semantics |
| 13 | Image/cache ve rebuild daraltma | Baseline ölçüm | Orta | [x] Görsel tarafı tamamlandı — 3 ham `Image.network` → `CachedNetworkImage`, gösterim boyutuna göre `memCacheWidth/Height`, tutarlı placeholder, galeride yalnız komşu sayfa `precacheImage`. **Rebuild daraltma (CartController id→quantity selector) bilinçli olarak yapılmadı:** plan §14.3 bunu profil ölçümü şartına bağlıyor, ölçüm cihazda yapılmalı. |
| 14 | Semantics/reduced motion/haptics | İlgili fazlar | Orta | [x] Tamamlandı — bottom nav item label/selected/badge, favori toggle state, stepper ürün adı + yeni miktar, carousel "görsel X / Y", skeleton tek "loading", icon-only close/share/download 44x44 + tooltip. Haptik yalnız 4 noktada: nav (`selectionClick`), segment (`selectionClick`), sepete ekleme kart + detay (`lightImpact`). Reduced motion `AppMotion.duration/reduceMotion` üzerinden cart fly, segment slide, shimmer, press ve favori çıkışında uygulanıyor. |
| 15 | Fırsat animasyonları A–D | P0/P1 tamam | Düşük-Orta | [x] Tamamlandı — **A** `AnimatedQuantityText` kart/detay/sepet satırında; **B** ortak `FilterPill` (3 kopya birleşti, 160 ms renk geçişi, clear ikonu 0.94→1, sonuç grid'i uçmuyor); **C** favoriler ve sepette üst seviye `AnimatedSwitcher` fade (stagger yok); **D** `OrderSuccessOverlay` — yalnız backend onayından sonra, tek sefer, reduced motion'da statik. |
| 16 | Son profil ve regresyon testi | Hepsi | Düşük | [ ] Cihaz gerektirir — kullanıcıda. `flutter analyze` + `flutter test` (32 test) geçiyor. |

Her sırayı ayrı commit/diff olarak tut. Bir faz ölçülebilir şekilde kötüleşirse yalnız o faz geri alınabilmeli.

## 19. Test planı

### Widget testleri

- `AppMotion.reduceMotion`: normal ve disableAnimations ortamı.
- Bottom nav: aynı index no-op; farklı index indicator hedefi; badge 0/1/çok haneli.
- ProductCard: add button → stepper; hızlı add; plus/minus; API rollback.
- Favorites: removal tamamlanınca controller/state cleanup; API hata rollback.
- BootstrapGate: success, Firebase failure, offline, timeout, dispose sonrası completion.
- Skeleton: TickerMode false ve reduced motion durumunda animation üretmemesi.

### Golden testler

- Bottom nav: seçili 5 state, badge state, büyük text scale.
- ProductCard: normal/favorite/in-cart/loading/error.
- Category segment: iki seçim, search açık/kapalı.
- Dialog/sheet: TK ve RU uzun metin; küçük ekran; text scale 1.3–1.5.

Animasyonun ara framelerini golden testle aşırı sabitleme. Başlangıç/bitiş state'i ve kritik bir orta frame yeterli.

### Manuel cihaz matrisi

- Android düşük/orta segment 60 Hz.
- Android gesture nav ve 3-button nav.
- iPhone 60 Hz ve mümkünse ProMotion 120 Hz.
- iOS Reduce Motion; Android Remove animations.
- TK ve RU; büyük sistem fontu.
- Offline, yavaş 3G, hızlı Wi-Fi.
- Cold start, warm start, background resume.

## 20. Her faz için zorunlu kalite kapısı

Her fazdan sonra:

```bash
dart format <yalnız değiştirilen dart dosyaları>
flutter analyze
flutter test
git diff --check
```

Ardından ilgili akışı `flutter run --profile` ile gerçek cihazda çalıştır. Yalnız analyzer'ın geçmesi animasyonun iyi hissettiğini kanıtlamaz.

### Feel-check

Ekran kaydını yavaş oynat ve kontrol et:

- Hareket dokunmadan hemen sonra mı başlıyor?
- Öğenin geldiği yön/başlangıç noktası mantıklı mı?
- Hedefte gereksiz bounce veya ikinci bir pop var mı?
- Animasyon yarıda tersine çevrilince sıçrıyor mu?
- İçerik layout'u animasyon boyunca oynuyor mu?
- Hızlı tekrar kullanımda hareket yorucu mu?
- Reduced motion'da bilgi kaybı oluyor mu?

## 21. Kapsam sınırları

- State management'i GetX'ten başka bir çözüme taşıma.
- Tasarım sistemini veya bütün UI'ı yeniden çizme.
- API sözleşmesini değiştirme.
- Sırf animasyon için yeni paket ekleme.
- Flutter/Gradle/iOS deployment upgrade'i bu işin içine katma.
- Kanıt olmadan bütün controller/model katmanını refactor etme.
- Kullanıcının mevcut icon, auth ve servis değişikliklerini geri alma.

Kod plan hazırlanırken değişmiş olabilir. Bir dosya veya snippet commit `141cb8f` ile uyuşmuyorsa tahmin ederek uygulama; önce güncel akışı yeniden incele ve planı o dosya için adapte et.

## 22. Son “done” kriteri

Bu plan ancak aşağıdakilerin tümü sağlandığında tamamlanmış sayılır:

- [x] Sabit splash gecikmesi yok — 2800 ms bekleme, DNS kilidi ve sahte yüzde kaldırıldı; `runApp` öncesi yalnız `GetStorage.init()` kaldı. Ölçüm cihazda yapılmalı.
- [x] Ana sayfa tek lazy sliver viewport kullanıyor (`CustomScrollView` + gerçek `SliverGrid`).
- [x] Scroll/build/item hot path'lerinde release/profile log yok — tüm `print` çağrıları `AppLog` üzerinden `kDebugMode`'a alındı, scroll listener ve parse döngüleri tamamen sessiz.
- [x] Bottom nav ve segment göstergeleri transform tabanlı.
- [x] Görünmeyen tab ticker'ları kapalı (`TickerMode` + kullanıldığında tick eden `ShimmerScope`).
- [x] ProductCard başına gereksiz controller yok.
- [x] Cart fly reduced motion'a uyuyor; `Transform.translate` ile çalışıyor, layout yazmıyor.
- [x] Motion duration/curve değerleri merkezi token'lardan geliyor (`AppMotion`).
- [x] Icon-only kritik kontroller semantic label ve yeterli hit target taşıyor.
- [x] Route geçişleri platforma uygun (`Transition.native`); iOS interactive back korunuyor.
- [x] `flutter analyze`, `flutter test` (32 test), `git diff --check` başarılı.
- [ ] Önce/sonra profile kayıtları — **cihazda alınmalı**.
- [ ] Android ve iOS gerçek cihaz feel-check — **cihazda yapılmalı**.

## 23. Uygulama notları (bu çalışmada yapılanlar)

### Yeni dosyalar

| Dosya | Ne için |
|---|---|
| `lib/core/theme/app_motion.dart` | Tek motion kaynağı: süre, eğri, press/enter ölçek tabanı, reduced-motion ve haptik politikası. |
| `lib/core/utils/app_log.dart` | Debug-only log; release/profile'da sıfır maliyet. |
| `lib/core/init/app_bootstrap.dart` | Idempotent, ilk frame'i bloklamayan servis başlatma. |
| `lib/core/services/push_registration.dart` | Bildirim izni ve FCM token kaydı; izin cold start'ta değil, girişten sonra isteniyor. |
| `lib/modules/splash/views/bootstrap_gate.dart` | Eski `SplashScreen`'in yerine geçen kapı; shell'i ilk frame'de kuruyor. |
| `lib/modules/splash/views/splash_brand.dart` | Native launch screen ile shell arasındaki tek statik marka karesi. |
| `lib/widgets/shimmer.dart` | `ShimmerScope` + `Shimmer`: ekran başına tek ticker, tek dış `ShaderMask`. |
| `lib/widgets/pressable.dart` | Ortak basma geri bildirimi (0.97 / 120 ms), reduced motion'da devre dışı. |
| `lib/widgets/animated_quantity_text.dart` | Stepper sayısı için ortak sayaç geçişi. |
| `lib/widgets/filter_pill.dart` | Üç ekrandaki kopyayı birleştiren animasyonlu filtre çipi. |
| `lib/widgets/order_success_overlay.dart` | Backend onayından sonra tek seferlik kutlama. |

### Silinen dosyalar

- `lib/modules/splash/views/splash_screen.dart` — `BootstrapGate` + `SplashBrand` ile değiştirildi.
- `category_screen.dart` içindeki yerel `BrandShimmer` — ortak shimmer dosyasına taşındı.

### Yol boyunca bulunan ve düzeltilen hatalar

1. **FCM endpoint'i hiç çalışmıyordu.** `POST 'api/user/fcm-token'` çağrılıyordu; base URL zaten `/api` içerdiği için istek `/api/api/user/fcm-token`'a gidiyordu ve yöntem de yanlıştı. `PATCH users/fcm-token` oldu (iki çağrı yerinde).
2. **`PhoneUtils.toLocal` bazı geçerli numaraları bozuyordu.** "993" ile başlayan 8 haneli yerel bir numarada ön ek kırpılıyor, numara 5 haneye düşüyordu. Widget testi yakaladı; kırpma artık yalnız 8 haneden uzun girdilerde yapılıyor.
3. **`NoInternetScreen` yanlış hosta bakıyordu.** `google.com` Türkmenistan'da engelli; çalışan bir bağlantıda "internet yok" diyordu. `atlas.com.tm` + 1500 ms timeout oldu.
4. **İki farklı background message handler kayıtlıydı.** `main.dart`'taki zengin (data-only bildirim gösteren) handler, `FirebaseMessagingService.init` tarafından log-only olanla eziliyordu. Tek ve zengin olanda birleştirildi.
5. **Favori kaldırma hatasında ürün listenin sonuna ekleniyordu.** Artık eski indeksine geri konuyor.
6. **`HomeScreen.build` içinde `Get.put(BrandsController())`** vardı; `MainBinding`'e taşındı.

### Bilinçli olarak yapılmayanlar

- **`CartController` id→quantity selector'ı.** Plan §14.3 bunu profil ölçümü şartına bağlıyor; ölçüm cihazda yapılmadan spekülatif refactor yapılmadı.
- **Büyük dosyaların bileşenlere ayrılması.** Plan §14 bunu "önce Faz 1–9 ölçümlerini tamamla" şartına bağlıyor.
- **`enterBottomSheetDuration` dışındaki GetX sheet/dialog API zorlamaları.** GetX 4.7'de app seviyesi dialog transition token'ı yok; çağrı başına `transitionDuration`/`transitionCurve` verildi, dependency yükseltilmedi.
