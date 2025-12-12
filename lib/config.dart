class AppConfig {
  // Backend API
  static const String defaultBackendUrl = 'http://10.0.2.2:3002'; // 10.0.2.2 points to host machine's localhost in Android emulator
  
  // Test Mode (desabilita chamadas de backend e usa dados mockados)
  static const bool testMode = true; // Mude para false quando tiver backend rodando
  
  // Breez SDK API Key (certificado nodeless)
  static const String breezApiKey = '''MIIBjDCCAT6gAwIBAgIHPom4vIYNvzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUxMDEyMTY0NTA4WhcNMzUxMDEwMTY0NTA4WjBAMSgwJgYDVQQKEx9BcmVhIEJpdGNvaW4gYW5kIEJpdGNvaW4gQ29kZXJzMRQwEgYDVQQDEwtDYXJvbCBTb3V6YTAqMAUGAytlcAMhANCD9cvfIDwcoiDKKYdT9BunHLS2/OuKzV8NS0SzqV13o4GGMIGDMA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTaOaPuXmtLDTJVv++VYBiQr9gHCTAfBgNVHSMEGDAWgBTeqtaSVvON53SSFvxMtiCyayiYazAjBgNVHREEHDAagRhjYXJvbEBhcmVhYml0Y29pbi5jb20uYnIwBQYDK2VwA0EAXZHGqrPXd8IVwVt7VNj3cKiYsdTo2Lz2B8HnR2Knd//bfoyO6MmBZHD0nszCIBLZTaiUiqgBN18YHfJnymK8DA==''';
  
  // App Info
  static const String appName = 'Bro';
  static const String appVersion = '1.0.0';
  
  // Network - MAINNET ATIVO (Bitcoin REAL)
  static const bool useMainnet = true; // PRODUÃ‡ÃƒO - Bitcoin de verdade
  
  // Features
  static const bool enableProviderMode = true;
  static const bool enableNotifications = true;
  
  // Provider Test Mode (permite testar sem garantias)
  static const bool providerTestMode = true; // Mude para false em produÃ§Ã£o
  
  // Fees
  static const double providerFeePercent = 0.05; // 5%
  static const double platformFeePercent = 0.02; // 2%
  
  // Limits
  static const int minPaymentSats = 1000; // 1k sats
  static const int maxPaymentSats = 1000000; // 1M sats
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int invoiceExpirySeconds = 3600; // 1 hora
}

