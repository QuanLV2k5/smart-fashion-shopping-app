import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../domain/personalization.dart';
import 'personalization_providers.dart';

class ReviewsPage extends ConsumerWidget {
  const ReviewsPage({required this.productId, super.key});
  final String productId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(personalizationUserIdProvider);
    return _Reviews(productId, userId, key: ValueKey((productId, userId)));
  }
}

class _Reviews extends ConsumerStatefulWidget {
  const _Reviews(this.productId, this.userId, {super.key});
  final String productId;
  final String? userId;
  @override
  ConsumerState<_Reviews> createState() => _ReviewsState();
}

class _ReviewsState extends ConsumerState<_Reviews> {
  int offset = 0;
  @override
  Widget build(BuildContext context) {
    final provider = reviewsProvider((
      userId: widget.userId,
      productId: widget.productId,
      offset: offset,
    ));
    final state = ref.watch(provider);
    final page = state.asData?.value;
    return ShopPageScaffold(
      title: 'Đánh giá sản phẩm',
      trailing: const CartButton(),
      onBack: () => context.canPop()
          ? context.pop()
          : context.go('/products/${widget.productId}'),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(provider);
          try {
            await ref.read(provider.future);
          } catch (_) {
            /* Rendered below. */
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (state.isLoading) const LinearProgressIndicator(),
            if (state.hasError)
              CatalogMessage(
                title: 'Chưa tải được đánh giá',
                message: personalizationMessage(state.error),
                error: true,
                action: 'Thử lại',
                onAction: () => ref.invalidate(provider),
              ),
            if (page != null) ...[
              Text(
                page.productName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                page.count == 0
                    ? 'Chưa có đánh giá'
                    : '${page.average.toStringAsFixed(1)}/5 · ${page.count} đánh giá',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bạn có thể viết đánh giá khi đơn hàng có sản phẩm này đã hoàn tất.',
                style: TextStyle(color: AppColors.muted),
              ),
              if (widget.userId == null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton(
                    onPressed: () => context.push(
                      '/login?next=${Uri.encodeComponent('/products/${widget.productId}/review')}',
                    ),
                    child: const Text('Đăng nhập để viết đánh giá'),
                  ),
                ),
              for (final review in page.reviews)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Text(
                            review.author,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          Text(
                            '${'★' * review.rating}${'☆' * (5 - review.rating)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 22,
                            ),
                          ),
                          const Text(
                            'Đã mua hàng',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                          if (review.body.isNotEmpty) Text(review.body),
                          Text(
                            '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (offset > 0 || page.hasMore)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: offset > 0
                            ? () => setState(() => offset -= 20)
                            : null,
                        child: const Text('Trang trước'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: page.hasMore
                            ? () => setState(() => offset += 20)
                            : null,
                        child: const Text('Trang sau'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
      footer: page?.canReview == true && !state.isLoading
          ? SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await context.push('/products/${widget.productId}/review');
                  if (mounted) ref.invalidate(provider);
                },
                child: Text(
                  page?.mine == null ? 'Viết đánh giá' : 'Sửa đánh giá của bạn',
                ),
              ),
            )
          : null,
    );
  }
}

class ReviewFormPage extends ConsumerWidget {
  const ReviewFormPage({required this.productId, super.key});
  final String productId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(personalizationUserIdProvider);
    return userId == null
        ? const SizedBox.shrink()
        : _ReviewForm(productId, userId, key: ValueKey((productId, userId)));
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm(this.productId, this.userId, {super.key});
  final String productId, userId;
  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  final body = TextEditingController();
  int rating = 0;
  bool initialized = false, busy = false, sent = false;
  String? message;
  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  bool get active =>
      mounted && ref.read(personalizationUserIdProvider) == widget.userId;
  Future<void> submit() async {
    final key = (userId: widget.userId, productId: widget.productId, offset: 0);
    if (busy ||
        rating < 1 ||
        !active ||
        ref.read(reviewsProvider(key)).asData?.value.canReview != true) {
      return;
    }
    if (body.text.trim().runes.length > 1000) {
      setState(() => message = 'Nhận xét tối đa 1.000 ký tự.');
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ref
          .read(personalizationRepositoryProvider)
          .submitReview(
            widget.userId,
            widget.productId,
            rating,
            body.text.trim(),
          );
      if (!active) return;
      ref.invalidate(reviewsProvider);
      setState(() => sent = true);
    } catch (error) {
      if (active) setState(() => message = personalizationMessage(error));
    } finally {
      if (active) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = reviewsProvider((
      userId: widget.userId,
      productId: widget.productId,
      offset: 0,
    ));
    final state = ref.watch(provider);
    final page = state.asData?.value;
    final product = ref.watch(productProvider(widget.productId)).asData?.value;
    if (!initialized && page != null) {
      initialized = true;
      rating = page.mine?.rating ?? 0;
      body.text = page.mine?.body ?? '';
    }
    return ShopPageScaffold(
      title: sent ? 'Cảm ơn đánh giá' : 'Đánh giá sản phẩm',
      trailing: const CartButton(),
      onBack: () => context.canPop()
          ? context.pop()
          : context.go('/products/${widget.productId}/reviews'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (state.isLoading || busy) const LinearProgressIndicator(),
          if (sent) ...[
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Cảm ơn bạn đã chia sẻ!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('Đánh giá đã được lưu và hiển thị trên sản phẩm.'),
          ] else ...[
            if (state.hasError)
              CatalogMessage(
                title: 'Chưa kiểm tra được điều kiện đánh giá',
                message: personalizationMessage(state.error),
                error: true,
                action: 'Thử lại',
                onAction: () => ref.invalidate(provider),
              ),
            if (message != null) ShopNotice(message!, error: true),
            if (page != null) ...[
              Row(
                children: [
                  if (product != null)
                    SizedBox(
                      width: 72,
                      height: 88,
                      child: ProductPhoto(product: product),
                    ),
                  if (product != null) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      page.productName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!page.canReview)
                const ShopNotice(
                  'Chỉ được đánh giá sản phẩm trong đơn đã hoàn tất của chính bạn.',
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var star = 1; star <= 5; star++)
                      IconButton(
                        tooltip: '$star sao',
                        onPressed: busy
                            ? null
                            : () => setState(() => rating = star),
                        icon: Icon(
                          star <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 32,
                          color: AppColors.accent,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: body,
                  enabled: !busy,
                  maxLength: 1000,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Nhận xét',
                    hintText: 'Chia sẻ trải nghiệm với sản phẩm',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chỉ dành cho sản phẩm trong đơn đã hoàn tất. Mỗi sản phẩm có một đánh giá của bạn; gửi lại sẽ cập nhật đánh giá đó.',
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ],
        ],
      ),
      footer: SizedBox(
        width: double.infinity,
        child: sent
            ? FilledButton(
                onPressed: () => context.pushReplacement(
                  '/products/${widget.productId}/reviews',
                ),
                child: const Text('Xem đánh giá'),
              )
            : FilledButton(
                onPressed:
                    busy ||
                        state.isLoading ||
                        page?.canReview != true ||
                        rating < 1
                    ? null
                    : submit,
                child: Text(
                  busy
                      ? 'Đang gửi…'
                      : rating == 0
                      ? 'Chọn số sao để gửi đánh giá'
                      : page?.mine == null
                      ? 'Gửi đánh giá'
                      : 'Cập nhật đánh giá',
                ),
              ),
      ),
    );
  }
}
