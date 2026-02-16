# 📝 Todo App

Minimalist tasarımı ve güçlü özellikleriyle günlük görevlerinizi yönetmek için geliştirilmiş bir Flutter uygulamasıdır.



## ✨ Özellikler

* 🔑 **Güvenli Giriş:** JWT tabanlı kullanıcı kimlik doğrulama.
* 🔄 **Kalıcı Oturum:** Uygulamayı her açtığınızda şifre girmeden giriş yapma (Auto-login).
* 🔔 **Akıllı Bildirimler:** Görevleriniz için zamanlanmış hatırlatıcılar.
* 📅 **Zaman Tüneli:** Tarih odaklı görev yönetimi ve takvim görünümü.
* 📊 **Dashboard:** Görevlerinizin durumunu gösteren hızlı istatistikler.
* 🔍 **Hızlı Arama & Sıralama:** Başlığa göre arama ve öncelik sıralaması.

## 🛠 Kullanılan Teknolojiler

* **Flutter** (Material 3 UI)
* **Provider** (Durum Yönetimi)
* **Shared Preferences** (Kalıcı Hafıza)
* **Local Notifications** (Bildirim Servisi)



## 🚀 Kurulum

1. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
.env dosyanızı oluşturup API URL'nizi ekleyin.

Uygulamayı çalıştırın:

Bash
flutter run
📂 Dosya Yapısı

lib/models: Veri modelleri.

lib/providers: Uygulama mantığı.

lib/screens: Arayüz tasarımları.

lib/services: API ve Bildirim servisleri.
