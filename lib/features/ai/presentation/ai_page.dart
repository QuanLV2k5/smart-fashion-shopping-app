import 'ai_conversation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/services/supabase_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../cart/domain/cart.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../../catalog/domain/catalog.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../data/supabase_ai_repository.dart';
import '../domain/ai_outfit.dart';

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => SupabaseAiRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(catalogRepositoryProvider),
  ),
);

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});
  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final form = GlobalKey<FormState>();
  final budget = TextEditingController(text: '500000');
  final notes = TextEditingController();
  String style = 'Casual', occasion = 'Đi chơi', audience = 'Unisex';
  bool busy = false;
  int revision = 0;
  AiOutfit? outfit;
  AiRequest? lastRequest;
  String? error;
  @override
  void dispose() {
    revision++;
    budget.dispose();
    notes.dispose();
    super.dispose();
  }

  void edit() {
    setState(() {
      revision++;
      busy = false;
      outfit = null;
      error = null;
    });
  }

  Future<void> generate({
    List<String> exclude = const [],
    List<String> keep = const [],
  }) async {
    if (busy || !(form.currentState?.validate() ?? true)) return;
    final user = ref.read(currentCartUserIdProvider);
    if (user == null) {
      context.push('/login?next=%2Fai');
      return;
    }
    final req = AiRequest(
      style: style,
      audience: audience,
      occasion: occasion,
      budget: int.parse(budget.text),
      notes: notes.text.trim(),
      excludeIds: exclude,
      keepIds: keep,
    );
    final current = ++revision;
    setState(() {
      busy = true;
      error = null;
      outfit = null;
      lastRequest = req;
    });
    try {
      final result = await ref.read(aiRepositoryProvider).recommend(req);
      if (!mounted ||
          current != revision ||
          ref.read(currentCartUserIdProvider) != user) {
        return;
      }
      setState(() => outfit = result);
    } catch (e) {
      if (mounted && current == revision) {
        setState(
          () => error = e is AiFailure
              ? e.message
              : 'Chưa tư vấn được. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted && current == revision) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentCartUserIdProvider, (previous, next) {
      if (previous != next) {
        setState(() {
          revision++;
          busy = false;
          outfit = null;
          error = null;
          notes.clear();
        });
      }
    });
    final result = outfit;
    return ShopPageScaffold(
      title: busy
          ? 'Đang phối đồ'
          : result == null
          ? 'Phối đồ AI'
          : result.products.isEmpty
          ? 'Chưa có bộ phù hợp'
          : 'Gợi ý dành cho bạn',
      onBack: () {
        if (busy || result != null || error != null) {
          edit();
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      trailing: const CartButton(),
      navigation: const AiBottomNavigation(),
      footer: busy
          ? null
          : SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: result == null && error == null
                    ? generate
                    : result == null
                    ? () => generate(
                        exclude: lastRequest?.excludeIds ?? const [],
                        keep: lastRequest?.keepIds ?? const [],
                      )
                    : result.products.isEmpty
                    ? edit
                    : () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        isDismissible: false,
                        enableDrag: false,
                        builder: (_) => OutfitCartSheet(
                          products: result.products,
                          budget: lastRequest!.budget,
                        ),
                      ),
                child: Text(
                  result == null
                      ? (error == null ? 'Gợi ý trang phục' : 'Thử lại')
                      : result.products.isEmpty
                      ? 'Điều chỉnh nhu cầu'
                      : 'Chọn size & thêm bộ · ${formatVnd(result.totalVnd)}',
                ),
              ),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: busy
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Text(
                    'Đang tìm bộ đồ\nhợp với bạn…',
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(color: AppColors.primary),
                  ),
                  for (var i = 0; i < 2; i++)
                    Container(
                      height: 170,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          for (final width in [double.infinity, 240.0, 280.0])
                            Container(
                              height: 28,
                              width: width,
                              decoration: BoxDecoration(
                                color: AppColors.outline,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const LinearProgressIndicator(),
                  const Text(
                    'Đối chiếu phong cách, ngân sách và sản phẩm còn hàng.',
                  ),
                  FilledButton.tonal(
                    onPressed: edit,
                    child: const Text('Hủy tư vấn'),
                  ),
                ],
              )
            : error != null
            ? CatalogMessage(
                title: 'Chưa thể tư vấn lúc này',
                message: error!,
                error: true,
                action: 'Điều chỉnh nhu cầu',
                onAction: edit,
              )
            : result != null
            ? result.products.isEmpty
                  ? CatalogMessage(
                      title: 'Ngân sách chưa đủ cho bộ này',
                      message:
                          'Chưa tìm thấy bộ đồ còn hàng dưới ${formatVnd(lastRequest!.budget)}. Tăng ngân sách hoặc thay đổi nhu cầu.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final updated = await showAiConversation(
                              context,
                              lastRequest!,
                              result,
                            );
                            if (!mounted || updated == null) return;
                            setState(() {
                              outfit = updated.outfit;
                              lastRequest = updated.request;
                              style = updated.request.style;
                              occasion = updated.request.occasion;
                              audience = updated.request.audience;
                              budget.text = '${updated.request.budget}';
                              notes.text = updated.request.notes;
                            });
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text('Trò chuyện & chỉnh bộ đồ'),
                        ),
                        Text(
                          '${lastRequest!.style.toUpperCase()} / ${lastRequest!.occasion.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.accent),
                        ),
                        Text(
                          'Một bộ đồ,\nnhiều cuộc hẹn.',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        Row(
                          spacing: 12,
                          children: [
                            for (final p in result.products.take(2))
                              Expanded(
                                child: SizedBox(
                                  height: 200,
                                  child: ProductPhoto(product: p),
                                ),
                              ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.sage,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 12,
                            children: [
                              Text(
                                'Bộ đồ dành cho bạn',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: AppColors.primary),
                              ),
                              Text(result.explanation),
                              Text(
                                '${formatVnd(result.totalVnd)} / ${formatVnd(lastRequest!.budget)}',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ),
                        ),
                        for (final p in result.products)
                          Column(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SizedBox(
                                  width: 72,
                                  height: 88,
                                  child: ProductPhoto(product: p),
                                ),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${formatVnd(p.priceVnd)} · Chọn size/màu',
                                ),
                                onTap: () => context.push('/products/${p.id}'),
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/products/${p.id}'),
                                    child: const Text('Xem & thêm món'),
                                  ),
                                  TextButton(
                                    onPressed: () => generate(
                                      exclude: [p.id],
                                      keep: result.products
                                          .where((other) => other.id != p.id)
                                          .map((other) => other.id)
                                          .toList(),
                                    ),
                                    child: const Text('Đổi món'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ShopNotice(
                          'Còn ${formatVnd(lastRequest!.budget - result.totalVnd)} trong ngân sách trang phục.',
                        ),
                        FilledButton.tonal(
                          onPressed: edit,
                          child: const Text('Điều chỉnh nhu cầu'),
                        ),
                      ],
                    )
            : Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.push('/ai/photo'),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Phối từ ảnh món đồ đã có'),
                    ),
                    Text(
                      'Hôm nay bạn\nmuốn mặc gì?',
                      style: Theme.of(context).textTheme.displaySmall
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const Text(
                      'Bộ đồ từ catalog, trong ngân sách của bạn.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    Text(
                      'Phong cách',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        for (final v in aiStyles)
                          ChoiceChip(
                            label: Text(v),
                            selected: style == v,
                            selectedColor: AppColors.primary,
                            checkmarkColor: AppColors.white,
                            labelStyle: TextStyle(
                              color: style == v
                                  ? AppColors.white
                                  : AppColors.muted,
                            ),
                            onSelected: (_) => setState(() => style = v),
                          ),
                      ],
                    ),
                    DropdownButtonFormField<String>(
                      key: ValueKey(occasion),
                      initialValue: occasion,
                      decoration: const InputDecoration(
                        labelText: 'Dịp sử dụng',
                      ),
                      items: [
                        for (final v in aiOccasions)
                          DropdownMenuItem(value: v, child: Text(v)),
                      ],
                      onChanged: (v) => setState(() => occasion = v!),
                    ),
                    TextFormField(
                      controller: budget,
                      decoration: const InputDecoration(
                        labelText: 'Ngân sách trang phục',
                        suffixText: 'VNĐ',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 50000 || n > 20000000
                            ? 'Nhập từ 50.000 đến 20.000.000đ.'
                            : null;
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: audience,
                      decoration: const InputDecoration(
                        labelText: 'Chọn trang phục cho',
                      ),
                      items: [
                        for (final v in ['Nam', 'Nữ', 'Unisex'])
                          DropdownMenuItem(value: v, child: Text(v)),
                      ],
                      onChanged: (v) => setState(() => audience = v!),
                    ),
                    TextFormField(
                      controller: notes,
                      maxLength: 500,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả thêm',
                        hintText: 'Bạn thích màu sắc, kiểu dáng nào?',
                      ),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.sage,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          style = 'Casual';
                          occasion = 'Đi chơi';
                          budget.text = '500000';
                          notes.clear();
                        });
                      },
                      child: const Text('Thử: casual đi chơi dưới 500.000đ'),
                    ),
                    const Text(
                      'Ngân sách tính tiền sản phẩm, chưa gồm phí giao hàng.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Uses the existing cart mutations, with per-item confirmation and partial success.
class OutfitCartSheet extends ConsumerStatefulWidget {
  const OutfitCartSheet({
    required this.products,
    required this.budget,
    super.key,
  });
  final List<CatalogProduct> products;
  final int budget;
  @override
  ConsumerState<OutfitCartSheet> createState() => _OutfitCartSheetState();
}

class _OutfitCartSheetState extends ConsumerState<OutfitCartSheet> {
  String? owner;
  @override
  void initState() {
    super.initState();
    owner = ref.read(currentCartUserIdProvider);
  }

  final selected = <String, String>{};
  final added = <String>{};
  bool writing = false;
  String? error;
  Future<void> add() async {
    if (writing) return;
    final user = ref.read(currentCartUserIdProvider);
    if (user == null || user != owner) {
      setState(() => error = 'Phiên đăng nhập đã thay đổi.');
      return;
    }
    if (widget.products.any((p) => !selected.containsKey(p.id))) {
      setState(() => error = 'Chọn size và màu cho từng món.');
      return;
    }
    setState(() {
      writing = true;
      error = null;
    });
    try {
      await ref.read(cartProvider(user).future);
      final freshProducts = <CatalogProduct>[];
      for (final p in widget.products) {
        final fresh = await ref
            .read(catalogRepositoryProvider)
            .loadProduct(p.id);
        if (fresh == null ||
            !fresh.variants.any((v) => v.id == selected[p.id] && v.stock > 0)) {
          throw const AiFailure(
            'Có món vừa hết hàng. Vui lòng xem lại sản phẩm.',
          );
        }
        freshProducts.add(fresh);
      }
      if (freshProducts.fold<int>(0, (sum, p) => sum + p.priceVnd) >
          widget.budget) {
        throw const AiFailure(
          'Giá sản phẩm vừa thay đổi, vượt ngân sách. Vui lòng tư vấn lại.',
        );
      }
      for (final p in widget.products) {
        if (added.contains(p.id)) continue;
        if (ref.read(currentCartUserIdProvider) != user) {
          throw const AiFailure('Phiên đăng nhập đã thay đổi.');
        }
        final fresh = await ref
            .read(catalogRepositoryProvider)
            .loadProduct(p.id);
        if (fresh == null ||
            !fresh.variants.any((v) => v.id == selected[p.id] && v.stock > 0)) {
          throw const AiFailure(
            'Có món vừa hết hàng. Vui lòng xem lại sản phẩm.',
          );
        }
        final ok = await ref
            .read(cartActionsProvider(user).notifier)
            .change(selected[p.id]!, 1, CartOperation.add);
        if (!mounted) return;
        if (!ok) {
          throw const AiFailure(
            'Có món chưa được xác nhận. Mở giỏ để kiểm tra và thử lại; các món đã thêm vẫn được giữ.',
          );
        }
        added.add(p.id);
      }
      if (mounted && ref.read(currentCartUserIdProvider) == user) {
        Navigator.pop(context);
        context.push('/cart');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is AiFailure
              ? e.message
              : 'Chưa thêm được. Kiểm tra giỏ và kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !writing,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Text(
            'Chọn size & màu cho bộ đồ',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final p in widget.products)
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(labelText: p.name),
              items: [
                for (final v in p.variants.where((v) => v.stock > 0))
                  DropdownMenuItem(
                    value: v.id,
                    child: Text(
                      '${v.size} · ${v.color}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: writing || added.contains(p.id)
                  ? null
                  : (v) => setState(() => selected[p.id] = v!),
              hint: Text(
                added.contains(p.id) ? 'Đã thêm vào giỏ' : 'Chọn biến thể',
              ),
            ),
          if (error != null) ShopNotice(error!, error: true),
          FilledButton(
            onPressed: writing ? null : add,
            child: Text(writing ? 'Đang thêm…' : 'Thêm bộ vào giỏ'),
          ),
          TextButton(
            onPressed: writing ? null : () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: writing
                ? null
                : () {
                    Navigator.pop(context);
                    context.push('/cart');
                  },
            child: const Text('Kiểm tra giỏ hàng'),
          ),
        ],
      ),
    ),
  );
}
