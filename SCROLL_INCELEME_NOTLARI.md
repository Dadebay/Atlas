# Login sonrası ana sayfa scroll incelemesi

## Kapsam ve bulgu özeti

İncelenen akış: **Profil > Giriş yap > başarılı girişten geri dön > Ana Sayfa sekmesine geç > dikey kaydırma**.

`HomeScreen` içindeki ana `SingleChildScrollView` doğrudan kapatılmamış: `AlwaysScrollableScrollPhysics` kullanıyor. Bu nedenle tek bir satırda bulunan kesin bir "scroll = false" hatası yok. Sorunun en kuvvetli adayı, ana dikey scroll alanı içinde tekrar tekrar kurulan dikey `GridView`/shimmer scroll alanları ve bunların birincil (`PrimaryScrollController`) davranışının açıkça sınırlandırılmamış olmasıdır. Login dönüşü sırasında yükleme durumları değiştiği için bu iç widget'lar ekrandaki ana scroll katmanını değiştirebilir.

Bu dosya kod değişikliği değil; Claude'un uygulaması için yapılacaklar listesidir.

## Öncelik 1 — Ana sayfayı tek bir dikey scroll sahibi olacak şekilde düzenle

**Dosya:** `lib/modules/home/views/home_screen.dart`  
**İlgili alanlar:** 78-286 (`SingleChildScrollView`, kategori grid'i, ürün grid'i)  
**Neden:** Ana `SingleChildScrollView` içinde hem kategori hem ürün grid'leri var. Bu grid'ler dikey `GridView` olduğu için ayrı `Scrollable` nesneleri yaratır. `NeverScrollableScrollPhysics` kullanılması kullanıcı drag'ini kapatır, fakat nested scroll/primary-controller sahipliğini tamamen açık ve güvenilir hale getirmez. Yüklenme ekranında başka bir `GridView` daha gelir.

**Tercih edilen çözüm:** Ana sayfayı `RefreshIndicator > CustomScrollView` yap ve tüm bölümleri `SliverToBoxAdapter`, `SliverGrid` ve gerekiyorsa `SliverPadding` ile oluştur. Böylece ekranda yalnızca bir dikey scroll pozisyonu olur.

**Alternatif, daha küçük çözüm:** Mevcut yapı korunacaksa içerideki her dikey `GridView.builder` için aşağıdakiler açıkça verilsin:

```dart
primary: false,
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
```

Bu ayar özellikle şu iki yerde uygulanmalı:

- Kategoriler yüklenirken gösterilen grid: `home_screen.dart` 318-323
- Kategoriler yüklendikten sonraki grid: `home_screen.dart` 366-371
- Tüm ürünler grid'i: `home_screen.dart` 252-257

> `NeverScrollableScrollPhysics` kaldırılmamalı. Amaç iç grid'i kaydırılabilir yapmak değil, yalnız ana üst scroll'un hareket etmesini sağlamaktır.

## Öncelik 2 — Ana sayfanın yüklenme shimmer'ını ana scroll ile çakıştırma

**Dosya:** `lib/widgets/product_card_shimmer.dart`  
**İlgili alan:** 377-389 (`ProductCardShimmerGrid`)  
**Çağrıldığı yer:** `lib/modules/home/views/home_screen.dart` 236-243

`ProductCardShimmerGrid`, yükleme sırasında ana `SingleChildScrollView` içine dikey bir `GridView.builder` ekliyor. Burada da `primary: false` açıkça verilmelidir. Daha sağlam çözümde shimmer, `CustomScrollView` içindeki bir `SliverGrid` olmalıdır.

Uygulanacak küçük düzeltme:

```dart
return GridView.builder(
  primary: false,
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  // mevcut diğer ayarlar
);
```

Bu ortak widget başka sayfalarda da kullanılıyor; değişiklikten sonra Favorites, kategori, marka ve ürün detayındaki loading görünümleri de test edilmeli.

## Öncelik 3 — Yatay listelerin dikey gesture'ı ana scroll'a bırakmasını garanti et

**Dosya:** `lib/modules/home/views/home_screen.dart`  
**İlgili alanlar:** 121-122 ve 191-192 (indirim/yeni ürün yatay listeleri)

Bu iki `ListView.builder` yatay olduğu için normalde dikey kaydırmayı ana alana iletir. Yine de nested scroll davranışını netleştirmek için `primary: false` eklenmeli; özellikle Android'de dikey-eğik parmak hareketlerinde gesture yarışını azaltır.

```dart
ListView.builder(
  primary: false,
  scrollDirection: Axis.horizontal,
  // mevcut ayarlar
)
```

**Dosya:** `lib/modules/home/widgets/home_widgets.dart`  
**İlgili alan:** 109-111 (`PageView.builder`)

Banner yatay `PageView` ana scroll'un en üstündedir. Sayfa aşağı kaydırılırken banner üzerinde de dikey kaydırmanın çalıştığını doğrulamak gerekir. Sorun yalnız banner üzerinde başlıyorsa `PageView` için `dragStartBehavior` / gesture davranışı cihazda test edilmeli; burada ilk aşamada rastgele physics değişikliği yapılmamalı.

## Öncelik 4 — Login dönüşünde klavye/focus'u kapat ve dönüşü deterministik yap

**Dosya:** `lib/modules/auth/views/login_view.dart`  
**İlgili alan:** 36-45 (`_submit`)

Başarılı girişte sadece `Get.back()` çağrılıyor. Giriş alanındaki focus/klavye kapanmadan route geri dönüyorsa, kullanıcı ana sayfaya geçince ilk gesture'ın klavyeyi veya eski focus'u kapatması gibi algılanabilir.

Claude'un eklemesi gereken güvenli davranış:

```dart
if (success) {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  if (mounted) Get.back(result: true);
}
```

Profil ekranında login sonucunu bekleyip sadece başarılı sonuçta gerekli UI yenilemesi yapılabilir. Bu, asıl nested-scroll düzeltmesinin yerine geçmez; login-sonrası semptomu daha güvenilir biçimde ayırmaya yarar.

## Öncelik 5 — Ana sayfanın scroll konumunu ve yaşam döngüsünü görünür hale getir

**Dosyalar:** `lib/modules/home/views/home_screen.dart`, `lib/modules/main/views/main_screen.dart`  
**İlgili alanlar:** 78 ve `IndexedStack` (21-30)

Geçici olarak ana scroll için bir `ScrollController` tanımlanıp `SingleChildScrollView`'a verilsin. Login sonrası şu noktalar loglanmalı:

- `hasClients`
- `position.pixels`
- `position.maxScrollExtent`
- `position.userScrollDirection`

`maxScrollExtent == 0` ise problem gesture değil, o andaki içerik yüksekliğidir. `maxScrollExtent > 0` olmasına rağmen `pixels` değişmiyorsa içteki scrollable/gesture katmanı sorumludur. Teşhis tamamlanınca debug logları kaldırılmalı.

`IndexedStack` ana sayfayı bellek içinde tutar. Bu istenen bir davranıştır; sadece login sonrasında Home widget'ını yeniden oluşturmak için `Get.put(BrandsController())` gibi controller kayıt işlemleri `build` içinde bırakılmamalı. Bu satır `home_screen.dart` 32'de; controller binding'e veya `HomeController.onInit` içine taşınmalı ya da `Get.find` kullanılmalı.

## Kabul testi

1. Uygulamayı kapatıp aç; ana sayfada ürünler yüklenirken ve yüklendikten sonra dikey scroll çalışmalı.
2. Profil sekmesi > Giriş yap > başarılı giriş > Ana Sayfa: banner, kategori alanı, yatay ürün listeleri ve ürün grid'i üzerinde dikey swipe dene.
3. Scroll en alta indikten sonra pull-to-refresh çalışmalı ve yenileme bittiğinde scroll yine hareket etmeli.
4. Ana Sayfa > Profil > Ana Sayfa geçişini art arda en az 5 kez dene; scroll konumu ve tepki tutarlı olmalı.
5. Android ve iOS'ta; küçük ekran ve büyük ekranla doğrula.
6. `flutter analyze` tekrar çalıştır. Mevcut analizde scroll ile ilgili derleme hatası yok; yalnız proje genelinde mevcut uyarılar var.

## Uygulama sırası

1. Önce 1 ve 2'yi uygula (tercihen `CustomScrollView`/sliver çözümü).
2. Sonra login focus temizliğini ekle.
3. Kabul testini hem loading hem veri yüklü durumda yap.
4. Sorun sürerse yalnız o zaman 5'teki geçici controller loglarıyla hangi widget'ın gesture'ı tuttuğunu belirle.
