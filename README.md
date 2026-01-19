<p align="center">
  <img src="assets/icons/bro_icon.png" alt="Bro Logo" width="120" height="120">
</p>

<h1 align="center">Bro</h1>

<p align="center">
  <strong>O app de escambo digital via Nostr</strong><br>
  Pague contas com Bitcoin. Troque com a comunidade. Sem bancos.
</p>

<p align="center">
  <a href="https://apps.apple.com/app/bro/id6740044498">
    <img src="https://img.shields.io/badge/App_Store-0D96F6?style=for-the-badge&logo=app-store&logoColor=white" alt="App Store">
  </a>
  <a href="https://play.google.com/store/apps/details?id=app.bro.mobile">
    <img src="https://img.shields.io/badge/Google_Play-414141?style=for-the-badge&logo=google-play&logoColor=white" alt="Google Play">
  </a>
  <a href="https://testflight.apple.com/join/YOUR_CODE">
    <img src="https://img.shields.io/badge/TestFlight-0D96F6?style=for-the-badge&logo=apple&logoColor=white" alt="TestFlight">
  </a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Lightning-792EE5?style=flat-square&logo=lightning&logoColor=white" alt="Lightning">
  <img src="https://img.shields.io/badge/Nostr-8B5CF6?style=flat-square&logo=nostr&logoColor=white" alt="Nostr">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="https://www.brostr.app">Website</a> •
  <a href="#features">Features</a> •
  <a href="#download">Download</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## 📖 About

**Bro** é uma plataforma P2P que permite pagar boletos e contas usando Bitcoin via Lightning Network, sem precisar de bancos ou intermediários.

Como funciona:
1. 📸 **Escaneie** seu boleto ou código PIX
2. ⚡ **Pague** com Bitcoin via Lightning
3. ✅ **Pronto** — um provedor da comunidade efetua o pagamento

Tudo isso de forma **trustless**, com garantias em Bitcoin e comunicação descentralizada via **Nostr**.

---

## ✨ Features

<table>
<tr>
<td width="50%">

### 👤 Para Usuários

- ⚡ Pague boletos e PIX com Bitcoin
- 📸 Scanner de código de barras e QR Code
- 🔐 Carteira Lightning self-custodial
- 📊 Acompanhamento em tempo real
- 📜 Histórico de transações
- 🔑 Login com chave Nostr (nsec)

</td>
<td width="50%">

### 💼 Para Provedores

- 📥 Receba ordens de pagamento
- 💰 Ganhe spread nas transações
- 🔒 Sistema de garantia (colateral)
- 📈 Dashboard de performance
- ⭐ Sistema de reputação
- 🏦 Liquidez sob demanda

</td>
</tr>
</table>

---

## 🔒 Por que Bro?

| | |
|:---:|---|
| **🔐 Self-Custodial** | Suas chaves, seu Bitcoin. Usamos Breez SDK Spark — você controla seus fundos. |
| **🌐 Descentralizado** | Comunicação via Nostr. Sem servidores centrais, sem single point of failure. |
| **🕵️ Privacidade** | Sem KYC, sem registro, sem número de telefone. Apenas sua chave Nostr. |
| **⚡ Instantâneo** | Pagamentos Lightning em segundos, não em dias. |
| **📖 Open Source** | Código 100% aberto. Audite, contribua, fork. |
| **🤝 Trustless** | Garantias em Bitcoin. Não precisa confiar, pode verificar. |

---

## 📱 Download

### Produção

| Plataforma | Link | Status |
|------------|------|--------|
| 🍎 iOS | [App Store](https://apps.apple.com/app/bro/id6740044498) | ✅ Disponível |
| 🤖 Android | [Google Play](https://play.google.com/store/apps/details?id=app.bro.mobile) | 🔜 Em breve |
| 📦 APK | [Releases](https://github.com/Quizzicarol/Bro/releases) | ✅ Disponível |

### Beta Testing

| Plataforma | Link |
|------------|------|
| 🍎 iOS Beta | [TestFlight](https://testflight.apple.com/join/YOUR_CODE) |
| 🤖 Android Beta | [APK Download](https://github.com/Quizzicarol/Bro/releases) |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        BRO APP                              │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (Flutter)                                         │
│  ├── Screens (Home, Wallet, Orders, Settings)               │
│  ├── Widgets (Reusable Components)                          │
│  └── Theme (Dark/Light Mode)                                │
├─────────────────────────────────────────────────────────────┤
│  State Management (Provider)                                │
│  ├── WalletProvider (Balance, Transactions)                 │
│  ├── OrderProvider (P2P Orders)                             │
│  └── AuthProvider (Nostr Keys)                              │
├─────────────────────────────────────────────────────────────┤
│  Services Layer                                             │
│  ├── BreezService (Lightning Network)                       │
│  ├── NostrService (P2P Communication)                       │
│  ├── StorageService (Secure Local Storage)                  │
│  └── ScannerService (Barcode/QR)                            │
├─────────────────────────────────────────────────────────────┤
│  External                                                   │
│  ├── Breez SDK Spark (Self-custodial Lightning)             │
│  ├── Nostr Relays (Decentralized Messaging)                 │
│  └── Backend (Order Matching)                               │
└─────────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Framework** | Flutter 3.x / Dart |
| **Lightning** | [Breez SDK Spark](https://breez.technology/sdk/) (self-custodial) |
| **Protocol** | [Nostr](https://nostr.com/) (NIPs 01, 04) |
| **State** | Provider + ChangeNotifier |
| **Storage** | SharedPreferences + FlutterSecureStorage |
| **CI/CD** | Codemagic |
| **Distribution** | App Store, Google Play, TestFlight |

---

## 🚀 Development

### Prerequisites

- Flutter 3.19+ ([Install](https://docs.flutter.dev/get-started/install))
- Dart 3.3+
- Android Studio / VS Code
- Xcode 15+ (para iOS)

### Quick Start

```bash
# Clone
git clone https://github.com/Quizzicarol/Bro.git
cd bro_app

# Install dependencies
flutter pub get

# Run
flutter run
```

### Build

```bash
# Android Release
flutter build apk --release

# iOS Release
flutter build ios --release

# Build Runner (if needed)
flutter pub run build_runner build
```

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── config.dart               # Environment configuration
├── models/                   # Data models
│   ├── order.dart
│   ├── transaction.dart
│   └── user.dart
├── providers/                # State management
│   ├── wallet_provider.dart
│   └── order_provider.dart
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── wallet_screen.dart
│   ├── orders_screen.dart
│   └── settings_screen.dart
├── services/                 # Business logic
│   ├── breez_service.dart    # Lightning Network
│   ├── nostr_service.dart    # P2P communication
│   └── storage_service.dart  # Local storage
├── theme/                    # App theming
│   ├── bro_colors.dart
│   └── bro_theme.dart
└── widgets/                  # Reusable components
```

---

## 🗺 Roadmap

- [x] ⚡ Pagamento de boletos via Lightning
- [x] 📸 Scanner de código de barras
- [x] 🔐 Carteira self-custodial (Breez SDK Spark)
- [x] 👤 Login com Nostr (nsec)
- [x] 💼 Modo Provedor
- [x] 🍎 iOS App Store
- [ ] 🤖 Google Play Store
- [ ] 🔄 Marketplace de trocas (escambo)
- [ ] 💬 Chat P2P entre usuários
- [ ] 🌍 Suporte multi-idioma
- [ ] 🖥 Versão Desktop

---

## 🤝 Contributing

Contribuições são bem-vindas! 

1. Fork o projeto
2. Crie sua feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add: AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### Code Style

- Seguimos o [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` antes de commits
- Mantenha cobertura de testes

---

## 📄 License

Distribuído sob a licença MIT. Veja [LICENSE](LICENSE) para mais informações.

---

## 📞 Contact

- 🌐 Website: [brostr.app](https://www.brostr.app)
- 🐙 GitHub: [@Quizzicarol](https://github.com/Quizzicarol)
- ⚡ Nostr: `npub...`

---

<p align="center">
  <strong>Quem tem Bro, tem tudo.</strong> 🟢⚡
</p>

<p align="center">
  Feito com 💚 para conectar pessoas
</p>
