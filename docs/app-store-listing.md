# App Store Connect — "Uçan Kafalar" Yayın Bilgileri

Apple onayı gelince App Store Connect'te uygulama oluştururken bu bilgileri kullan.
Kopyala-yapıştır hazır.

---

## Temel Bilgiler
- **Uygulama Adı (Name):** Uçan Kafalar
- **Alt Başlık (Subtitle, maks. 30 karakter):** Uç, zıpla, borulardan geç!
- **Bundle ID:** `com.ucankafalar.flappybird`
- **SKU:** `ucankafalar001` (benzersiz herhangi bir metin)
- **Birincil Dil:** Türkçe (Turkish)
- **Kategori:** Games → Arcade (İkincil: Casual)
- **Yaş Sınırı:** 4+ (şiddet/uygunsuz içerik yok)
- **Fiyat:** Ücretsiz (Free)

## Açıklama (Description — TR)
```
Uçan Kafalar'a hoş geldin! Tek parmakla oyna: ekrana dokun, kafan zıplasın,
borulara çarpmadan aralarından süzül. Basit ama bırakması zor!

🕹️ ÖZELLİKLER
• 10 farklı karakter — skor yaptıkça yenilerini aç
• 4 zorluk modu: Kolay, Orta, Zor ve giderek hızlanan Macera modu
• Her karaktere özel arka plan müziği
• En yüksek skorun kaydedilir
• Reklam izleyerek kaldığın yerden devam et

Reflekslerini test etmeye hazır mısın? En yüksek skoru kim yapacak?
```

## Anahtar Kelimeler (Keywords, virgülle, maks. 100 karakter)
```
uçan,kafa,flappy,kuş,zıpla,boru,arcade,refleks,oyun,skor,uçmak,kolay
```

## URL'ler
- **Destek URL (Support URL):** https://github.com/omerycoskun/ucan-kafalar
  *(veya bir iletişim sayfası; App Store zorunlu tutar)*
- **Gizlilik Politikası URL (Privacy Policy URL):**
  https://omerycoskun.github.io/ucan-kafalar/privacy-policy.html
  *(GitHub Pages'i aktifleştirdikten sonra çalışır — aşağıya bak)*

---

## App Store Gizlilik Beyanı (App Privacy)
App Store Connect "App Privacy" bölümünde şunları beyan et (AdMob nedeniyle):
- **Toplanan veri türü:** Identifiers → Device ID (reklam kimliği)
- **Kullanım amacı:** Third-Party Advertising (üçüncü taraf reklam)
- **Kullanıcıya bağlı mı?** Genelde "Data Not Linked to You" seçilir
- **İzleme (Tracking):** Evet — reklam kimliği izleme için kullanılır (ATT izni soruluyor)
- Oyun skoru/ayarları cihazda kaldığı için **toplanan veri değildir**, beyan edilmez.

---

## Ekran Görüntüleri (Screenshots)
App Store en az **1 adet 6.7" iPhone** ekran görüntüsü ister (1290 × 2796 px).
Öneri: 3-5 adet, oyunun farklı ekranlarından:
1. Ana menü (UÇAN KAFALAR logosu görünür)
2. Oyun anı (kafa borular arasında, skor üstte)
3. Karakter seçim ekranı (kilitli/açık karakterler)
4. Zorluk/ayarlar ekranı
5. Oyun bitti ekranı (skor + İzle & Devam Et)

Bunları TestFlight build'i telefona gelince gerçek cihazdan çekeceğiz.

---

## GitHub Pages'i aktifleştir (gizlilik URL'si için)
1. https://github.com/omerycoskun/ucan-kafalar → **Settings** → sol menü **Pages**
2. **Source:** "Deploy from a branch"
3. **Branch:** `main`, klasör **/docs** seç → **Save**
4. 1-2 dakika sonra şu adres çalışır:
   `https://omerycoskun.github.io/ucan-kafalar/privacy-policy.html`
5. Bu adresi App Store'daki "Privacy Policy URL" alanına yapıştır.
