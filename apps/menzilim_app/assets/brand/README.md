# MENZİLİM marka varlıkları

Özgün olarak MENZİLİM için tasarlandı: "M" harfinin iç çizgileri, hedefe
(bullseye) varan iki yol gibi birleşir — "Hedefini belir. Yolunu keşfet."

| Dosya | Kullanım |
| --- | --- |
| `menzilim_mark.svg` | Uygulama içindeki sembol. Tek renktir (`currentColor`); `MenzilimLogoMark` tema rengiyle boyar. |
| `menzilim_app_icon.svg` | Marka renkli zemin üzerinde sembol. Web favicon ve mağaza simgelerinin kaynağı; `web/favicon.svg` bunun kopyasıdır. |

## Uygulama içinde

- `MenzilimLogoMark` — yalnızca sembol (`boxed: true` ile marka renkli kutu içinde).
- `MenzilimWordmark` — yalnızca "MENZİLİM" yazısı (Türkçe "İ" korunur).
- `MenzilimLogo` — sembol + yazı (`showTagline: true` ile slogan).

Üçü de `core/design/design_system.dart` üzerinden dışa aktarılır.

## Simgeleri yeniden üretme

Sembolün geometrisi değişirse `menzilim_mark.svg`, `menzilim_app_icon.svg` ve
`tools/render_brand_icons.py` içindeki sabitler birlikte güncellenmelidir.

```
python tools/render_brand_icons.py
```

`web/favicon.png` ile `web/icons/*` dosyalarını yeniden üretir (Pillow gerekir).

## Mobil simgeler

Android/iOS simgeleri bu sprintte üretilmedi. Kaynak olarak
`menzilim_app_icon.svg` (512×512, güvenli alan için %18 boşluk) hazırdır;
mağaza simgeleri bu dosyadan türetilebilir.
