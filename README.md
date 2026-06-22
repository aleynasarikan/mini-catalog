# Mini Catalog

Mini Catalog, eğitim amaçlı hazırlanmış şık bir Flutter katalog uygulamasıdır. Uygulama ürün listeleme, ürün detayları, sepet yönetimi, favori ürünler ve kategori filtreleme özellikleri içerir.

## Proje Adı

- Mini Catalog

## Kısa Açıklama

Mini Catalog, kullanıcıların ürünleri görüntüleyebildiği, favorilere ekleyebildiği ve sepetine ekleyebildiği modern bir Flutter alışveriş uygulamasıdır.

## Kullanılan Flutter Sürümü

- Flutter SDK: 3.12.x veya üzeri
- Dart SDK: 3.12.x veya üzeri

## Çalıştırma Adımları

1. Depoyu klonlayın veya indirin.
2. Terminalde proje kök dizinine gidin:

```bash
cd mini_catalog
```

3. Paketleri yükleyin:

```bash
flutter pub get
```

4. Uygulamayı çalıştırın:

```bash
flutter run
```

## Özellikler

- Ana sayfa ürün kartları ile katalog görünümü
- Ürün detay ekranı
- Sepete ekleme ve sepetten kaldırma
- Favori ürünler (wishlist)
- Arama ve kategori filtreleme
- Harici API'den veya yerel JSON dosyasından veri yükleme

## Notlar

- Uygulama önce `https://wantapi.com/products.php` adresinden veri çekmeyi dener.
- Ağ bağlantısı başarısız olursa `temp_api.json` içinde saklanan yerel JSON verisi yüklenir.
- `pubspec.yaml` dosyasında `temp_api.json` asset olarak tanımlıdır.

## Proje Çıktıları

Bu proje ile öğrenciler aşağıdaki yetkinliklere sahip olacaktır:

- Flutter widget ağacını kavrama
- Sayfalar arası geçiş (Navigator)
- Model sınıfı ve JSON parse işlemi
- GridView ile ürün kartı tasarımı
- Basit durum yönetimi ve sepet fonksiyonları
- Asset yönetimi ve yerel veri kullanımı

## Ekran Görüntüleri

Aşağıdaki örnek ekran görüntülerini `screenshots/` dizinine ekledim:

- `screenshots/home.png`
- `screenshots/product_detail.png`
- `screenshots/cart.png`

Bu screenshot’lar placeholder olarak eklendi; istersen gerçek uygulama görüntüleriyle değiştirebilirsin.

## Teslim ve Değerlendirme Kriterleri

Projeyi teslim ederken aşağıdaki kriterlere dikkat edin:

- **Repository**: Proje GitHub üzerinde public bir repository olarak paylaşılmalıdır.
- **README**: Projede çalıştırma adımları, Flutter sürümü ve kısa açıklama yer almalıdır.
- **Çalışır Durum**: Uygulama `flutter run` ile çalışır durumda olmalıdır.
- **Assets**: `temp_api.json` veya ilgili görseller `assets`/`screenshots` dizininde bulunmalı ve `pubspec.yaml` içinde tanımlanmalıdır.
- **Ekran Görüntüleri**: `screenshots/` dizininde en az ana ekran, ürün detay ve sepet ekranlarının görüntüleri yer almalıdır.

Değerlendirme checklist (öğrenci dolduracak):

- [ ] Repository public ve erişilebilir
- [ ] README.md içinde proje adı ve çalıştırma adımları var
- [ ] Uygulama çalışıyor (emülatör veya cihazda)
- [ ] `temp_api.json` veya API kaynakları açıkça belirtilmiş
- [ ] Ekran görüntüleri `screenshots/` içinde yer alıyor

---
