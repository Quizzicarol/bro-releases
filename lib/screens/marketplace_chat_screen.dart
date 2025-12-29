import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/nostr_service.dart';

/// Tela de chat P2P via Nostr DM (NIP-04)
class MarketplaceChatScreen extends StatefulWidget {
  final String recipientPubkey;
  final String recipientName;
  final String? offerTitle;

  const MarketplaceChatScreen({
    super.key,
    required this.recipientPubkey,
    required this.recipientName,
    this.offerTitle,
  });

  @override
  State<MarketplaceChatScreen> createState() => _MarketplaceChatScreenState();
}

class _MarketplaceChatScreenState extends State<MarketplaceChatScreen> {
  final NostrService _nostrService = NostrService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  
  final List<String> _relays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.primal.net',
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    // Mostrar guia de boas práticas na primeira vez
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showBestPracticesGuide();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showBestPracticesGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Negociação Segura',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideItem(
                '🔒',
                'Escrow quando possível',
                'Use o sistema de escrow do Bro para pagamentos de contas.',
              ),
              _buildGuideItem(
                '⚡',
                'Prefira Lightning',
                'Pagamentos Lightning são instantâneos e irreversíveis.',
              ),
              _buildGuideItem(
                '🔍',
                'Verifique reputação',
                'Cheque referências e histórico do vendedor.',
              ),
              _buildGuideItem(
                '💬',
                'Documente tudo',
                'Mantenha prints das conversas e comprovantes.',
              ),
              _buildGuideItem(
                '⚠️',
                'Valores pequenos primeiro',
                'Comece com transações menores para testar.',
              ),
              _buildGuideItem(
                '🚫',
                'Nunca compartilhe',
                'Sua seed phrase, chave privada ou senhas.',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ O Bro não é responsável por negociações P2P fora do escrow. Negocie por sua conta e risco.',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final myPubkey = _nostrService.publicKey;
      if (myPubkey == null) {
        throw Exception('Não logado');
      }
      
      // Buscar mensagens do Nostr (NIP-04 DMs)
      final messages = await _fetchDMsFromNostr(myPubkey, widget.recipientPubkey);
      
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Erro ao carregar mensagens: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<ChatMessage>> _fetchDMsFromNostr(String myPubkey, String otherPubkey) async {
    final messages = <ChatMessage>[];
    
    for (final relay in _relays.take(2)) {
      try {
        final channel = WebSocketChannel.connect(Uri.parse(relay));
        final completer = Completer<List<Map<String, dynamic>>>();
        final events = <Map<String, dynamic>>[];
        
        channel.stream.listen(
          (data) {
            final decoded = jsonDecode(data);
            if (decoded[0] == 'EVENT') {
              events.add(decoded[2]);
            } else if (decoded[0] == 'EOSE') {
              completer.complete(events);
            }
          },
          onError: (e) => completer.completeError(e),
        );
        
        // Buscar DMs enviadas por mim para o destinatário
        final subId1 = 'dm_sent_${DateTime.now().millisecondsSinceEpoch}';
        final req1 = Request(subId1, [
          Filter(
            kinds: [4], // NIP-04 DM
            authors: [myPubkey],
            p: [otherPubkey],
            limit: 50,
          ),
        ]);
        channel.sink.add(req1.serialize());
        
        // Buscar DMs recebidas do destinatário
        final subId2 = 'dm_recv_${DateTime.now().millisecondsSinceEpoch}';
        final req2 = Request(subId2, [
          Filter(
            kinds: [4],
            authors: [otherPubkey],
            p: [myPubkey],
            limit: 50,
          ),
        ]);
        channel.sink.add(req2.serialize());
        
        final result = await completer.future.timeout(const Duration(seconds: 5));
        await channel.sink.close();
        
        // Processar eventos
        for (final event in result) {
          try {
            final content = await _decryptDM(event['content'], event['pubkey']);
            final isFromMe = event['pubkey'] == myPubkey;
            
            messages.add(ChatMessage(
              id: event['id'],
              content: content,
              isFromMe: isFromMe,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (event['created_at'] as int) * 1000,
              ),
            ));
          } catch (e) {
            debugPrint('Erro ao decriptar DM: $e');
          }
        }
        
        break; // Sucesso, não precisa tentar outro relay
      } catch (e) {
        debugPrint('Erro ao buscar DMs de $relay: $e');
      }
    }
    
    // Ordenar por timestamp
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  Future<String> _decryptDM(String encryptedContent, String senderPubkey) async {
    try {
      final privateKey = _nostrService.privateKey;
      if (privateKey == null) return '[Mensagem encriptada]';
      
      // Usar NIP-04 decrypt
      final keychain = Keychain(privateKey);
      final decrypted = keychain.nip04Decrypt(senderPubkey, encryptedContent);
      return decrypted;
    } catch (e) {
      debugPrint('Erro decrypt: $e');
      return '[Erro ao decriptar]';
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    
    setState(() => _isSending = true);
    
    try {
      final privateKey = _nostrService.privateKey;
      if (privateKey == null) throw Exception('Não logado');
      
      final keychain = Keychain(privateKey);
      
      // Encriptar mensagem (NIP-04)
      final encrypted = keychain.nip04Encrypt(widget.recipientPubkey, text);
      
      // Criar evento DM
      final event = Event.from(
        kind: 4, // NIP-04 DM
        tags: [
          ['p', widget.recipientPubkey],
        ],
        content: encrypted,
        privkey: privateKey,
      );
      
      // Publicar em relays
      int successCount = 0;
      for (final relay in _relays) {
        try {
          final channel = WebSocketChannel.connect(Uri.parse(relay));
          channel.sink.add(event.serialize());
          await Future.delayed(const Duration(milliseconds: 200));
          await channel.sink.close();
          successCount++;
        } catch (e) {
          debugPrint('Erro ao enviar para $relay: $e');
        }
      }
      
      if (successCount > 0) {
        // Adicionar mensagem localmente
        setState(() {
          _messages.add(ChatMessage(
            id: event.id,
            content: text,
            isFromMe: true,
            timestamp: DateTime.now(),
          ));
        });
        
        _messageController.clear();
        _scrollToBottom();
      } else {
        throw Exception('Falha ao enviar');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recipientName, style: const TextStyle(fontSize: 16)),
            if (widget.offerTitle != null)
              Text(
                widget.offerTitle!,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showBestPracticesGuide,
            tooltip: 'Dicas de Segurança',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMessages,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lista de mensagens
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                  : _messages.isEmpty
                      ? _buildEmptyChat()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                        ),
            ),
            
            // Campo de mensagem
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Digite sua mensagem...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF2E2E2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma mensagem ainda',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Envie uma mensagem para ${widget.recipientName}',
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            if (widget.offerTitle != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 Dica: Mencione a oferta "${widget.offerTitle}" na sua mensagem.',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isFromMe ? Colors.orange : const Color(0xFF2E2E2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isFromMe ? 16 : 4),
            bottomRight: Radius.circular(message.isFromMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: message.isFromMe ? Colors.white : Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: message.isFromMe ? Colors.white70 : Colors.white38,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String id;
  final String content;
  final bool isFromMe;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isFromMe,
    required this.timestamp,
  });
}
