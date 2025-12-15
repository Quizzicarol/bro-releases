/// Decodificador local de boletos bancários brasileiros
/// Suporta boletos tradicionais (47 dígitos) e boletos de concessionárias (48 dígitos)
class BoletoDecoderService {
  
  /// Decodifica linha digitável do boleto e extrai o valor
  /// Retorna null se não for um boleto válido
  static Map<String, dynamic>? decodeBoleto(String code) {
    // Limpar código - remover espaços, pontos e hífens
    final cleanCode = code.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanCode.isEmpty) return null;
    
    // Boleto bancário tradicional: 47 dígitos
    if (cleanCode.length == 47) {
      return _decodeBoletoTradicional(cleanCode);
    }
    
    // Boleto de concessionária/convênio: 48 dígitos
    if (cleanCode.length == 48) {
      return _decodeBoletoConvenio(cleanCode);
    }
    
    // Código de barras direto: 44 dígitos
    if (cleanCode.length == 44) {
      return _decodeCodigoBarras(cleanCode);
    }
    
    return null;
  }
  
  /// Decodifica boleto bancário tradicional (47 dígitos)
  /// Formato: AAABC.CCCCX DDDDD.DDDDDY EEEEE.EEEEEZ K UUUUVVVVVVVVVV
  /// Onde o valor está nos últimos 10 dígitos (VVVVVVVVVV)
  static Map<String, dynamic>? _decodeBoletoTradicional(String code) {
    try {
      // Converter linha digitável para código de barras
      // Campo 5 (posições 33-47): UUUU + Valor (10 dígitos)
      // Mas na linha digitável está em posição diferente
      
      // Na linha digitável de 47 dígitos:
      // Posições 5-9: parte do código do banco
      // Posições 10-14: parte do código do banco
      // Posições 21-31: campo livre (parte)
      // Posição 33-36: fator de vencimento
      // Posição 37-46: valor (10 dígitos, 8 inteiros + 2 decimais)
      
      // O valor fica nas posições 37-46 na linha digitável (índice 36-45)
      // Mas precisamos reconstruir o código de barras primeiro
      
      // Extrair campos da linha digitável
      final campo1 = code.substring(0, 10);   // Posições 1-10
      final campo2 = code.substring(10, 21);  // Posições 11-21
      final campo3 = code.substring(21, 32);  // Posições 22-32
      final campo4 = code.substring(32, 33);  // Posição 33 (dígito verificador geral)
      final campo5 = code.substring(33, 47);  // Posições 34-47 (vencimento + valor)
      
      // Extrair valor do campo 5 (últimos 10 dígitos representam o valor)
      final valorStr = campo5.substring(4, 14); // Pular fator vencimento (4 dígitos)
      final valorCentavos = int.tryParse(valorStr) ?? 0;
      final valor = valorCentavos / 100.0;
      
      // Extrair fator de vencimento para calcular data
      final fatorVencimento = int.tryParse(campo5.substring(0, 4)) ?? 0;
      DateTime? dataVencimento;
      if (fatorVencimento > 0) {
        // Base: 07/10/1997
        final dataBase = DateTime(1997, 10, 7);
        dataVencimento = dataBase.add(Duration(days: fatorVencimento));
      }
      
      // Extrair código do banco (3 primeiros dígitos)
      final codigoBanco = code.substring(0, 3);
      final nomeBanco = _getNomeBanco(codigoBanco);
      
      return {
        'success': true,
        'billType': 'boleto',
        'type': 'boleto_bancario',
        'value': valor,
        'merchantName': nomeBanco,
        'bankCode': codigoBanco,
        'dueDate': dataVencimento?.toIso8601String(),
        'barcode': code,
        'message': 'Boleto decodificado localmente',
      };
    } catch (e) {
      print('❌ Erro ao decodificar boleto tradicional: $e');
      return null;
    }
  }
  
  /// Decodifica boleto de concessionária/convênio (48 dígitos)
  /// Usado para contas de luz, água, gás, IPTU, etc.
  static Map<String, dynamic>? _decodeBoletoConvenio(String code) {
    try {
      // Boletos de convênio têm estrutura diferente
      // O primeiro dígito indica o tipo de valor:
      // 8 = valor a cobrar efetivo ou referência
      // 6 ou 7 = valor de referência
      
      final identificador = code.substring(0, 1);
      
      // O valor pode estar em posições diferentes dependendo do tipo
      // Para maioria: posições 5-15 (11 dígitos) com 2 casas decimais
      String valorStr;
      
      if (identificador == '8') {
        // Arrecadação - valor nos campos
        // Identificação do Segmento (posição 2)
        final segmento = code.substring(1, 2);
        
        // Valor: geralmente nas posições 5-15
        valorStr = code.substring(4, 15);
      } else {
        // Outros tipos
        valorStr = code.substring(4, 15);
      }
      
      final valorCentavos = int.tryParse(valorStr) ?? 0;
      final valor = valorCentavos / 100.0;
      
      // Identificar o tipo de convênio pelo segmento
      final segmento = code.substring(1, 2);
      String tipoConvenio = 'Convênio';
      switch (segmento) {
        case '1':
          tipoConvenio = 'Prefeituras';
          break;
        case '2':
          tipoConvenio = 'Saneamento';
          break;
        case '3':
          tipoConvenio = 'Energia/Gás';
          break;
        case '4':
          tipoConvenio = 'Telecomunicações';
          break;
        case '5':
          tipoConvenio = 'Órgãos Governamentais';
          break;
        case '6':
          tipoConvenio = 'Outros';
          break;
        case '7':
          tipoConvenio = 'Multas de Trânsito';
          break;
        case '9':
          tipoConvenio = 'Outros';
          break;
      }
      
      return {
        'success': true,
        'billType': 'boleto',
        'type': 'boleto_convenio',
        'value': valor,
        'merchantName': tipoConvenio,
        'barcode': code,
        'message': 'Boleto de convênio decodificado localmente',
      };
    } catch (e) {
      print('❌ Erro ao decodificar boleto convênio: $e');
      return null;
    }
  }
  
  /// Decodifica código de barras direto (44 dígitos)
  static Map<String, dynamic>? _decodeCodigoBarras(String code) {
    try {
      // Código de barras de boleto bancário (44 dígitos):
      // Posições 1-3: Código do banco
      // Posição 4: Código da moeda (9 = Real)
      // Posição 5: Dígito verificador geral
      // Posições 6-9: Fator de vencimento
      // Posições 10-19: Valor (10 dígitos, 8 inteiros + 2 decimais)
      // Posições 20-44: Campo livre
      
      final codigoBanco = code.substring(0, 3);
      final fatorVencimento = int.tryParse(code.substring(5, 9)) ?? 0;
      final valorStr = code.substring(9, 19);
      final valorCentavos = int.tryParse(valorStr) ?? 0;
      final valor = valorCentavos / 100.0;
      
      DateTime? dataVencimento;
      if (fatorVencimento > 0) {
        final dataBase = DateTime(1997, 10, 7);
        dataVencimento = dataBase.add(Duration(days: fatorVencimento));
      }
      
      final nomeBanco = _getNomeBanco(codigoBanco);
      
      return {
        'success': true,
        'billType': 'boleto',
        'type': 'codigo_barras',
        'value': valor,
        'merchantName': nomeBanco,
        'bankCode': codigoBanco,
        'dueDate': dataVencimento?.toIso8601String(),
        'barcode': code,
        'message': 'Código de barras decodificado localmente',
      };
    } catch (e) {
      print('❌ Erro ao decodificar código de barras: $e');
      return null;
    }
  }
  
  /// Retorna o nome do banco pelo código
  static String _getNomeBanco(String codigo) {
    final bancos = {
      '001': 'Banco do Brasil',
      '033': 'Santander',
      '104': 'Caixa Econômica',
      '237': 'Bradesco',
      '341': 'Itaú',
      '356': 'Banco Real',
      '389': 'Mercantil do Brasil',
      '399': 'HSBC',
      '422': 'Safra',
      '453': 'Rural',
      '633': 'Rendimento',
      '652': 'Itaú Unibanco',
      '745': 'Citibank',
      '756': 'Sicoob',
      '748': 'Sicredi',
      '077': 'Inter',
      '260': 'Nubank',
      '336': 'C6 Bank',
      '212': 'Original',
      '655': 'Votorantim',
      '246': 'ABC Brasil',
      '025': 'Alfa',
      '641': 'Alvorada',
      '029': 'Banerj',
      '000': 'Bankpar',
      '740': 'Barclays',
      '107': 'BBM',
      '031': 'Beg',
      '096': 'BM&F',
      '318': 'BMG',
      '752': 'BNP Paribas',
      '248': 'Boavista',
      '218': 'Bonsucesso',
      '065': 'Bracce',
      '036': 'Bradesco BBI',
      '394': 'Bradesco Financiamentos',
      '204': 'Bradesco Cartões',
      '225': 'Brascan',
      '044': 'BVA',
      '263': 'Cacique',
      '473': 'Caixa Geral',
      '040': 'Cargill',
      '745': 'Citibank',
      '477': 'Citibank',
      '081': 'Concórdia',
      '707': 'Daycoval',
      '487': 'Deutsche',
      '751': 'Dresdner',
      '064': 'Goldman Sachs',
      '062': 'Hipercard',
      '399': 'HSBC',
      '168': 'HSBC Finance',
      '492': 'ING',
      '998': 'Itaú',
      '652': 'Itaú Holding',
      '341': 'Itaú Unibanco',
      '079': 'JBS',
      '376': 'J.P. Morgan',
      '074': 'J. Safra',
      '600': 'Luso Brasileiro',
      '389': 'Mercantil do Brasil',
      '746': 'Modal',
      '045': 'Opportunity',
      '079': 'Original Agro',
      '623': 'Pan',
      '611': 'Paulista',
      '613': 'Pecúnia',
      '094': 'Petra',
      '643': 'Pine',
      '747': 'Rabobank',
      '633': 'Rendimento',
      '741': 'Ribeirão Preto',
      '453': 'Rural',
      '422': 'Safra',
      '033': 'Santander',
      '955': 'Santander',
      '250': 'Schahin',
      '749': 'Simples',
      '366': 'Société Générale',
      '637': 'Sofisa',
      '012': 'Standard',
      '082': 'Topázio',
      '464': 'Sumitomo',
      '634': 'Triângulo',
      '208': 'UBS Pactual',
      '116': 'Único',
      '655': 'Votorantim',
      '610': 'VR',
      '370': 'Mizuho',
      '021': 'Banestes',
      '719': 'Banif',
      '755': 'Bank of America',
      '744': 'BankBoston',
      '073': 'BB Cartões',
      '078': 'BES',
      '069': 'BPN',
      '070': 'BRB',
      '249': 'Credicard',
      '075': 'CR2',
      '088': 'Fator',
      '233': 'GE Capital',
      '612': 'Guanabara',
      '630': 'Intercap',
      '077': 'Inter',
      '653': 'Indusval',
      '249': 'Investcred',
      '184': 'Itaú BBA',
      '479': 'Itaú Bank Boston',
      '604': 'Industrial do Brasil',
      '320': 'Industrial e Comercial',
      '653': 'Indusval',
    };
    
    return bancos[codigo] ?? 'Banco $codigo';
  }
}
