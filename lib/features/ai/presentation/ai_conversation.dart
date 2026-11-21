import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/formatters/money.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../cart/presentation/cart_providers.dart';
import '../domain/ai_outfit.dart';
import '../data/supabase_ai_repository.dart';

final chatTransportProvider =
    Provider<Future<Map<String, dynamic>> Function(Map<String, dynamic>)>((
      ref,
    ) {
      final client = ref.watch(supabaseClientProvider);
      return (body) async {
        if (client == null) throw const AiFailure('Dịch vụ AI chưa sẵn sàng.');
        final response = await client.functions
            .invoke('ai-outfits', body: body)
            .timeout(const Duration(seconds: 110));
        if (response.status != 200) {
          throw AiFailure(
            SupabaseAiRepository.messageForCode(
              (response.data as Map?)?['code'],
            ),
          );
        }
        return Map<String, dynamic>.from(response.data as Map);
      };
    });
const aiStyles = [
  'Casual',
  'Tối giản',
  'Công sở',
  'Streetwear',
  'Thể thao',
  'Thanh lịch',
  'Vintage',
];
const aiOccasions = [
  'Đi chơi',
  'Đi làm',
  'Đi học',
  'Dự tiệc',
  'Hẹn hò',
  'Du lịch',
  'Bảo vệ đồ án',
];

class AiBottomNavigation extends StatelessWidget {
  const AiBottomNavigation({super.key});
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: 3,
    onDestinationSelected: (i) {
      if (i != 3) context.go(const ['/', '/explore', '/account', '/ai'][i]);
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        label: 'Trang chủ',
      ),
      NavigationDestination(icon: Icon(Icons.search), label: 'Khám phá'),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Tài khoản',
      ),
      NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        label: 'AI Stylist',
      ),
    ],
  );
}

class ConversationResult {
  const ConversationResult(this.request, this.outfit);
  final AiRequest request;
  final AiOutfit outfit;
}

Future<ConversationResult?> showAiConversation(
  BuildContext context,
  AiRequest request,
  AiOutfit outfit,
) => showModalBottomSheet<ConversationResult>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  builder: (_) => AiConversation(request: request, outfit: outfit),
);

class AiConversation extends ConsumerStatefulWidget {
  const AiConversation({
    required this.request,
    required this.outfit,
    super.key,
  });
  final AiRequest request;
  final AiOutfit outfit;
  @override
  ConsumerState<AiConversation> createState() => _AiConversationState();
}

class _AiConversationState extends ConsumerState<AiConversation> {
  late AiRequest request = widget.request;
  late AiOutfit outfit = widget.outfit;
  late Set<String> locks = widget.request.keepIds.toSet();
  final text = TextEditingController();
  final scroll = ScrollController();
  final messages = <({bool user, String text})>[];
  bool busy = false;
  int revision = 0;
  String? error;
  @override
  void dispose() {
    revision++;
    text.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? quick]) async {
    final message = (quick ?? text.text).trim();
    if (busy || message.isEmpty) return;
    final owner = ref.read(currentCartUserIdProvider);
    if (owner == null) {
      setState(() => error = 'Vui lòng đăng nhập để trò chuyện.');
      return;
    }
    final token = ++revision;
    setState(() {
      busy = true;
      error = null;
      messages.add((user: true, text: message));
      text.clear();
    });
    try {
      final data = await ref.read(chatTransportProvider)({
        ...request.toJson(),
        'action': 'chat',
        'keepIds': locks.toList(),
        'currentIds': outfit.products.map((p) => p.id).toList(),
        'message': message,
      });
      if (!mounted ||
          revision != token ||
          ref.read(currentCartUserIdProvider) != owner) {
        return;
      }
      if (data['provider'] != 'gemini' ||
          data['chatVersion'] != 1 ||
          data['message'] is! String) {
        throw const FormatException();
      }
      final raw = Map<String, dynamic>.from(data['request'] as Map);
      if (jsonEncode(raw['ownedGarment']) !=
          jsonEncode(request.ownedGarment?.toJson())) {
        throw const FormatException();
      }
      final next = AiRequest(
        style: raw['style'] as String,
        occasion: raw['occasion'] as String,
        budget: raw['budget'] as int,
        audience: raw['audience'] as String,
        notes: raw['notes'] as String,
        keepIds: List<String>.from(raw['keepIds'] as List),
        ownedGarment: request.ownedGarment,
      );
      AiOutfit? nextOutfit;
      if (data['outfit'] != null) {
        final value = Map<String, dynamic>.from(data['outfit'] as Map);
        final ids = (value['products'] as List)
            .map((p) => (p as Map)['id'] as String)
            .toList();
        if (ids.isEmpty ||
            ids.length > 4 ||
            ids.toSet().length != ids.length ||
            next.keepIds.any((id) => !ids.contains(id))) {
          throw const FormatException();
        }
        final catalog = await ref.read(catalogRepositoryProvider).loadCatalog();
        nextOutfit = AiOutfit(
          products: ids
              .map((id) => catalog.products.firstWhere((p) => p.id == id))
              .toList(),
          explanation: value['explanation'] as String,
        );
        if (nextOutfit.totalVnd > next.budget ||
            nextOutfit.products.any((p) => !p.inStock)) {
          throw const AiFailure('Giá hoặc tồn kho vừa thay đổi. Hãy thử lại.');
        }
      }
      if (!mounted ||
          revision != token ||
          ref.read(currentCartUserIdProvider) != owner) {
        return;
      }
      setState(() {
        if (nextOutfit != null) {
          outfit = nextOutfit;
          request = next;
          locks = next.keepIds.toSet();
        }
        messages.add((user: false, text: data['message'] as String));
      });
    } catch (e) {
      if (mounted && revision == token) {
        setState(
          () => error = e is AiFailure
              ? e.message
              : 'Chưa cập nhật được bộ đồ. Kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted && revision == token) {
        setState(() => busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentCartUserIdProvider, (a, b) {
      if (a != b) {
        revision++;
        Navigator.of(context).pop();
      }
    });
    return PopScope(
      canPop: !busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Trò chuyện với AI Stylist',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng hội thoại',
                      onPressed: () {
                        revision++;
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  children: [
                    const Text(
                      'Chọn món cần giữ, rồi nhắn điều bạn muốn thay đổi. Món đã có từ ảnh luôn được giữ. Hội thoại lưu trong phiên này.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    for (final p in outfit.products)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.name),
                        subtitle: Text('${formatVnd(p.priceVnd)} · Giữ món'),
                        value: locks.contains(p.id),
                        onChanged: busy
                            ? null
                            : (v) {
                                if (v == true && locks.length >= 3) {
                                  setState(() => error = 'Giữ tối đa 3 món.');
                                  return;
                                }
                                setState(() {
                                  v == true
                                      ? locks.add(p.id)
                                      : locks.remove(p.id);
                                });
                              },
                      ),
                    Text(
                      'Mua thêm: ${formatVnd(outfit.totalVnd)} / ${formatVnd(request.budget)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (messages.isEmpty)
                      const Text(
                        'Ví dụ: “Giữ quần, đổi áo”, “Tìm đôi giày rẻ hơn”, “Tôi muốn bộ dưới 400 nghìn”.',
                      ),
                    for (final m in messages)
                      Align(
                        alignment: m.user
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: m.user ? AppColors.primary : AppColors.sage,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            m.text,
                            style: TextStyle(
                              color: m.user ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    if (busy)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: LinearProgressIndicator(),
                      ),
                    if (error != null)
                      Text(
                        error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Tìm món rẻ hơn'),
                      onPressed: busy
                          ? null
                          : () => send('Tìm món rẻ hơn cho những món chưa giữ'),
                    ),
                    ActionChip(
                      label: const Text('Gợi ý thanh lịch hơn'),
                      onPressed: busy
                          ? null
                          : () => send('Tôi muốn bộ đồ thanh lịch hơn'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: text,
                        enabled: !busy,
                        maxLength: 400,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Bạn muốn thay đổi gì?',
                          counterText: '',
                        ),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Gửi tin nhắn',
                      onPressed: busy ? null : send,
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () => Navigator.pop(
                            context,
                            ConversationResult(
                              AiRequest(
                                style: request.style,
                                occasion: request.occasion,
                                budget: request.budget,
                                audience: request.audience,
                                notes: request.notes,
                                keepIds: locks.toList(),
                                ownedGarment: request.ownedGarment,
                              ),
                              outfit,
                            ),
                          ),
                    child: const Text('Áp dụng bộ đồ này'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
