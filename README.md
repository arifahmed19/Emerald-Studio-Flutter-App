# 📸 Emerald Studio

A professional-grade, unified Flutter application designed to automate the creation of official passport photos for any country. Built with a focus on high-end aesthetics (**Glassmorphism** & **Emerald Palette**) and cross-platform performance.

---

## 💎 Features

*   **⚡ Pro-Visuals**: Stunning dark-mode emerald theme with a modern translucent (glassmorphism) design across the entire user experience.
*   **📐 Precise Formatting**: Automated cropping and alignment based on international standards (US 2x2, UK 35x45mm, and more).
*   **📱 Unified Experience**: Fully responsive design that scales perfectly from small mobile screens to large desktop monitors.
*   **🖨️ One-Click Printing**: Generate high-resolution, printable A4 PDF templates with correctly sized and spaced photo sets.
*   **🔐 Secure Backend**: Powered by **Supabase** for robust authentication and high-resolution photo storage in the cloud.
*   **📷 Guided Capture**: (Mobile) Custom camera overlay for perfect face alignment in every shot.

---

## 🛠️ Technical Stack

*   **Frontend**: Flutter (Dart)
*   **Backend**: Supabase (Database, Auth, and Storage)
*   **Architecture**: Provider (State Management)
*   **Design**: Vanilla CSS with custom Theme Extensions
*   **PDF Engine**: Printing & Pdf package for printable template generation
*   **UI Assets**: Google Fonts (Outfit) & Lucide-style icons

---

## 🚀 Getting Started

### 1. Prerequisites
*   Flutter SDK installed
*   A Supabase account (Free Tier)

### 2. Setup Backend
1. Create a project in [Supabase](https://app.supabase.com).
2. Create a public bucket in **Storage** named `photos`.
3. Disable "Confirm Email" in **Authentication > Settings**.

### 3. Local Installation
```bash
git clone https://github.com/arifahmed19/Passport-Photo-Studio-Unified-Flutter-App.git
cd Passport-Photo-Studio-Unified-Flutter-App
flutter pub get
```

### 4. Configuration
Open `lib/main.dart` and paste your Supabase keys:
```dart
await Supabase.initialize(
  url: 'YOUR_PROJECT_URL',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 5. Run the App
```bash
flutter run -d chrome  # For Web
# OR
flutter run            # For Mobile
```

---

## 📂 Project Structure

```text
lib/
├── core/         # Custom Emerald Theme & Theme Tokens
├── models/       # Passport Sizing Standards (International)
├── providers/    # Auth & Passport Processing Logic
├── screens/      # Glassmorphism UI Screens (Auth, Home, Editor)
└── main.dart     # Entry point & Supabase Initialization
```

---

## 👨‍💻 Created By
**Arif Ahmed**  
[*GitHub Portfolio*](https://github.com/arifahmed19)
