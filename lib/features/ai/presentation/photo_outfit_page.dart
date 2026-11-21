import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formatters/money.dart';
import '../../../core/services/supabase_provider.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/shop_page_scaffold.dart';
import '../../cart/presentation/cart_providers.dart';
import '../../cart/presentation/widgets/cart_button.dart';
import '../../catalog/presentation/widgets/catalog_widgets.dart';
import '../data/device_garment_photo_picker.dart';
import '../data/supabase_garment_repository.dart';
import '../domain/ai_outfit.dart';
import '../domain/owned_garment.dart';
import 'ai_page.dart';

final garmentRepositoryProvider = Provider<GarmentRepository>(
  (ref) => SupabaseGarmentRepository(ref.watch(supabaseClientProvider)),
);
final garmentPhotoPickerProvider = Provider<GarmentPhotoPicker>(
  (ref) => DeviceGarmentPhotoPicker(),
);

class PhotoOutfitPage extends ConsumerStatefulWidget {
  const PhotoOutfitPage({super.key});
  @override
  ConsumerState<PhotoOutfitPage> createState() => _PhotoOutfitPageState();
}

class _PhotoOutfitPageState extends ConsumerState<PhotoOutfitPage> {
  final attributesForm = GlobalKey<FormState>();
  final needsForm = GlobalKey<FormState>();
  final name = TextEditingController();
  final color = TextEditingController();
  final pattern = TextEditingController();
  final fit = TextEditingController();
  final details = TextEditingController();
  final budget = TextEditingController(text: '500000');
  final notes = TextEditingController();
  final scroll = ScrollController();
  GarmentCategory category = GarmentCategory.top;
  String style = 'Casual', occasion = 'Đi chơi';
  int step = 0, revision = 0;
  bool busy = false;
  String busyLabel = '', error = '';
  GarmentPhoto? photo;
  OwnedGarment? owned;
  AiOutfit? result;
  AiRequest? lastRequest;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => recover());
  }

  @override
  void dispose() {
    revision++;
    for (final c in [name, color, pattern, fit, details, budget, notes]) {
      c.dispose();
    }
    scroll.dispose();
    super.dispose();
  }

  void top() {
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  bool active(int token, String user) =>
      mounted &&
      revision == token &&
      ref.read(currentCartUserIdProvider) == user;
  String failure(Object e) => e is AiFailure
      ? e.message
      : e is PlatformException
      ? 'Chưa mở được ảnh hoặc máy ảnh. Kiểm tra quyền ứng dụng rồi thử lại.'
      : 'Chưa thực hiện được. Kiểm tra kết nối rồi thử lại.';

  Future<void> recover() async {
    final user = ref.read(currentCartUserIdProvider);
    if (user == null) return;
    final token = revision;
    try {
      final recovered = await ref.read(garmentPhotoPickerProvider).recover();
      if (!active(token, user) || recovered == null || photo != null || busy) {
        return;
      }
      setState(() {
        photo = recovered;
        error = '';
      });
    } catch (e) {
      if (active(token, user)) setState(() => error = failure(e));
    }
  }

  Future<void> pick(bool camera) async {
    if (busy) return;
    final user = ref.read(currentCartUserIdProvider);
    if (user == null) return;
    final token = ++revision;
    setState(() {
      busy = true;
      busyLabel = 'Đang mở ảnh';
      error = '';
    });
    try {
      final selected = await ref
          .read(garmentPhotoPickerProvider)
          .pick(camera: camera);
      if (!active(token, user) || selected == null) return;
      setState(() {
        photo = selected;
        owned = null;
        result = null;
        step = 0;
      });
    } catch (e) {
      if (active(token, user)) setState(() => error = failure(e));
    } finally {
      if (active(token, user)) setState(() => busy = false);
    }
  }

  Future<void> analyze() async {
    final selected = photo;
    final user = ref.read(currentCartUserIdProvider);
    if (busy || selected == null || user == null) return;
    final token = ++revision;
    setState(() {
      busy = true;
      busyLabel = 'Đang nhận diện món đồ';
      error = '';
    });
    try {
      final garment = await ref
          .read(garmentRepositoryProvider)
          .analyze(selected);
      if (!active(token, user)) return;
      setState(() {
        category = garment.category;
        name.text = garment.name;
        color.text = garment.color;
        pattern.text = garment.pattern;
        fit.text = garment.fit;
        details.text = garment.details;
        owned = null;
        step = 1;
      });
      top();
    } catch (e) {
      if (active(token, user)) setState(() => error = failure(e));
    } finally {
      if (active(token, user)) setState(() => busy = false);
    }
  }

  void confirm() {
    if (!(attributesForm.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      owned = OwnedGarment(
        category: category,
        name: name.text.trim(),
        color: color.text.trim(),
        pattern: pattern.text.trim(),
        fit: fit.text.trim(),
        details: details.text.trim(),
      );
      step = 2;
      error = '';
      result = null;
    });
    top();
  }

  Future<void> generate({
    List<String> exclude = const [],
    List<String> keep = const [],
  }) async {
    final user = ref.read(currentCartUserIdProvider);
    if (busy ||
        owned == null ||
        user == null ||
        !(needsForm.currentState?.validate() ?? true)) {
      return;
    }
    final request = AiRequest(
      style: style,
      occasion: occasion,
      budget: int.parse(budget.text),
      notes: notes.text.trim(),
      ownedGarment: owned,
      excludeIds: exclude,
      keepIds: keep,
    );
    FocusScope.of(context).unfocus();
    final token = ++revision;
    setState(() {
      busy = true;
      busyLabel = 'Đang phối với món bạn đã có';
      error = '';
      result = null;
      lastRequest = request;
    });
    try {
      final outfit = await ref.read(aiRepositoryProvider).recommend(request);
      if (!active(token, user)) return;
      setState(() => result = outfit);
      top();
    } catch (e) {
      if (active(token, user)) setState(() => error = failure(e));
    } finally {
      if (active(token, user)) setState(() => busy = false);
    }
  }

  void back() {
    if (busy) {
      setState(() {
        revision++;
        busy = false;
        error = '';
      });
      return;
    }
    if (result != null) {
      setState(() => result = null);
      top();
      return;
    }
    if (step > 0) {
      setState(() => step--);
      top();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/ai');
    }
  }

  void addToCart() {
    final outfit = result;
    if (outfit == null || outfit.products.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => OutfitCartSheet(
        products: outfit.products,
        budget: lastRequest!.budget,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentCartUserIdProvider, (previous, next) {
      if (previous == next) return;
      setState(() {
        revision++;
        busy = false;
        photo = null;
        owned = null;
        result = null;
        lastRequest = null;
        step = 0;
        error = '';
        for (final c in [name, color, pattern, fit, details, notes]) {
          c.clear();
        }
      });
    });
    final outfit = result;
    return PopScope(
      canPop: !busy && step == 0 && outfit == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: ShopPageScaffold(
        title: 'Phối đồ từ ảnh',
        onBack: back,
        trailing: const CartButton(),
        footer: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy
                ? back
                : step == 0
                ? (photo == null ? null : analyze)
                : step == 1
                ? confirm
                : outfit == null
                ? generate
                : outfit.products.isEmpty
                ? () => setState(() => result = null)
                : addToCart,
            icon: Icon(
              busy
                  ? Icons.close
                  : step == 2 && outfit != null && outfit.products.isNotEmpty
                  ? Icons.shopping_bag_outlined
                  : Icons.auto_awesome_outlined,
            ),
            label: Text(
              busy
                  ? 'Hủy thao tác'
                  : step == 0
                  ? 'Nhận diện món đồ'
                  : step == 1
                  ? 'Xác nhận món đồ'
                  : outfit == null
                  ? 'Tìm món phối cùng'
                  : outfit.products.isEmpty
                  ? 'Điều chỉnh nhu cầu'
                  : 'Chọn món mua thêm · ${formatVnd(outfit.totalVnd)}',
            ),
          ),
        ),
        body: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0)
                      const Expanded(child: Divider(indent: 6, endIndent: 6)),
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: i <= step
                          ? AppColors.primary
                          : AppColors.outline,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          color: i <= step ? AppColors.white : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                [
                  'Bắt đầu từ\nmón bạn yêu thích.',
                  'AI đã nhìn thấy gì?',
                  'Phối mới,\ngiữ chất riêng.',
                ][step],
                style: Theme.of(context).textTheme.displaySmall
                    ?.copyWith(color: AppColors.primary),
              ),
              Text(
                [
                  'Chụp riêng một món đồ. Tìm những món còn thiếu để hoàn thiện bộ trang phục.',
                  'Kiểm tra và sửa lại thông tin trước khi phối. Ánh sáng có thể làm màu ảnh khác thực tế.',
                  'Món bạn đã có được giữ lại. Ngân sách chỉ dành cho sản phẩm mua thêm.',
                ][step],
                style: const TextStyle(color: AppColors.muted),
              ),
              if (error.isNotEmpty) ShopNotice(error, error: true),
              if (busy) _loading(),
              if (!busy && step == 0) ..._upload(),
              if (!busy && step == 1) _attributes(),
              if (!busy && step == 2) ...[
                _ownedCard(),
                if (outfit == null) _preferences() else ..._results(outfit),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _loading() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppColors.sage,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      spacing: 16,
      children: [
        const SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        Text(
          busyLabel,
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const Text(
          'Có thể mất vài chục giây. Bạn có thể hủy và thử lại.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _photo({double height = 240}) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: ColoredBox(
      color: AppColors.white,
      child: Image.memory(
        photo!.bytes,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        semanticLabel: 'Ảnh món đồ của bạn',
        errorBuilder: (_, _, _) => const SizedBox(
          height: 180,
          child: Center(child: Text('Ảnh không đọc được. Hãy chọn ảnh khác.')),
        ),
      ),
    ),
  );

  List<Widget> _upload() => [
    if (photo != null)
      _photo()
    else
      Container(
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.sage,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 12,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            Text(
              'Một món đồ. Nhiều cách phối.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Áo · quần · đầm · giày · phụ kiện',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => pick(true),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Chụp ảnh'),
        ),
        OutlinedButton.icon(
          onPressed: () => pick(false),
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(photo == null ? 'Chọn ảnh' : 'Đổi ảnh'),
        ),
      ],
    ),
    const _PhotoTip(
      icon: Icons.light_mode_outlined,
      title: 'Ảnh rõ sẽ tư vấn tốt hơn',
      text: 'Đặt một món đồ trên nền đơn giản, chụp đủ sáng và thấy trọn món. JPG, PNG hoặc WebP, tối đa 2 MB.',
    ),
    const _PhotoTip(
      icon: Icons.privacy_tip_outlined,
      title: 'Bạn kiểm soát ảnh của mình',
      text: 'Ảnh được gửi tới Gemini để nhận diện. Chỉ chụp món đồ, tránh khuôn mặt và thông tin riêng. Chưa lưu thành tủ đồ cá nhân.',
    ),
  ];

  Widget _attributes() => Form(
    key: attributesForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        _photo(height: 180),
        const _PhotoTip(
          icon: Icons.auto_awesome_outlined,
          title: 'Nhận diện bằng Gemini',
          text: 'Các thông tin dưới đây là gợi ý từ ảnh. Hãy sửa những gì chưa đúng; mục chưa rõ có thể giữ “Chưa rõ”.',
        ),
        DropdownButtonFormField<GarmentCategory>(
          initialValue: category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Loại món đồ'),
          items: [
            for (final v in GarmentCategory.values)
              DropdownMenuItem(value: v, child: Text(v.label)),
          ],
          onChanged: (v) => setState(() => category = v!),
        ),
        _field(name, 'Tên món đồ', 80),
        _field(color, 'Màu chủ đạo', 40),
        _field(pattern, 'Họa tiết', 50),
        _field(fit, 'Kiểu dáng nhìn thấy', 50),
        _field(details, 'Đặc điểm khác', 220, lines: 3),
        TextButton.icon(
          onPressed: () => setState(() => step = 0),
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('Chọn ảnh và nhận diện lại'),
        ),
      ],
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label,
    int max, {
    int lines = 1,
  }) => TextFormField(
    controller: controller,
    maxLength: max,
    maxLines: lines,
    decoration: InputDecoration(labelText: label, counterText: ''),
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Nhập thông tin hoặc ghi “Chưa rõ”.'
        : null,
  );

  Widget _ownedCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.sage,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        const Row(
          spacing: 8,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 18,
              color: AppColors.primary,
            ),
            Text(
              'BẠN ĐÃ CÓ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            SizedBox(width: 70, child: _photo(height: 86)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    owned!.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${owned!.color} · ${owned!.pattern}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  const Text(
                    'Không tính vào tiền mua thêm',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => setState(() {
            step = 1;
            result = null;
          }),
          child: const Text('Sửa thông tin món đồ'),
        ),
      ],
    ),
  );

  Widget _preferences() => Form(
    key: needsForm,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Text(
          'Bạn muốn mặc đi đâu?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        DropdownButtonFormField<String>(
          initialValue: occasion,
          decoration: const InputDecoration(labelText: 'Dịp sử dụng'),
          items: [
            for (final v in ['Đi chơi', 'Đi làm', 'Đi học', 'Dự tiệc'])
              DropdownMenuItem(value: v, child: Text(v)),
          ],
          onChanged: (v) => setState(() => occasion = v!),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in ['Casual', 'Tối giản', 'Công sở'])
              ChoiceChip(
                label: Text(v),
                selected: style == v,
                onSelected: (_) => setState(() => style = v),
              ),
          ],
        ),
        TextFormField(
          controller: budget,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: const InputDecoration(
            labelText: 'Ngân sách mua thêm',
            suffixText: 'VNĐ',
          ),
          validator: (v) {
            final n = int.tryParse(v ?? '');
            return n == null || n < 50000 || n > 20000000
                ? 'Nhập từ 50.000 đến 20.000.000đ.'
                : null;
          },
        ),
        TextFormField(
          controller: notes,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Mong muốn của bạn',
            hintText: 'Ví dụ: đi bảo vệ đồ án, lịch sự nhưng trẻ trung; tránh màu đen.',
          ),
        ),
        const Text(
          'Tư vấn dựa trên màu, kiểu dáng món đã có và sản phẩm còn hàng. Ngân sách chưa gồm phí giao hàng.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );

  List<Widget> _results(AiOutfit outfit) => [
    if (outfit.products.isEmpty) ...[
      const CatalogMessage(
        title: 'Chưa tìm được món phối phù hợp',
        message: 'Catalog hiện chưa có phương án đáp ứng món đã có và ngân sách của bạn. Hãy đổi nhu cầu hoặc thử món đồ khác.',
      ),
    ] else ...[
      Text(
        'Mua thêm để hoàn thiện bộ đồ',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Row(
              spacing: 8,
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: AppColors.accent,
                ),
                Text(
                  'GỢI Ý TỪ GEMINI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            Text(outfit.explanation),
            Text(
              'Mua thêm: ${formatVnd(outfit.totalVnd)}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: AppColors.primary),
            ),
            Text(
              'Còn ${formatVnd(lastRequest!.budget - outfit.totalVnd)} trong ngân sách',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
      for (final p in outfit.products)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Material(
                color: AppColors.white,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 64,
                    height: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProductPhoto(product: p),
                    ),
                  ),
                  title: Text(p.name),
                  subtitle: Text(formatVnd(p.priceVnd)),
                  onTap: () => context.push('/products/${p.id}'),
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    onPressed: () => context.push('/products/${p.id}'),
                    child: const Text('Xem sản phẩm'),
                  ),
                  TextButton(
                    onPressed: () => generate(
                      exclude: [p.id],
                      keep: outfit.products
                          .where((v) => v.id != p.id)
                          .map((v) => v.id)
                          .toList(),
                    ),
                    child: const Text('Đổi món này'),
                  ),
                ],
              ),
            ],
          ),
        ),
      const Text(
        'Chọn đúng màu được gợi ý và size phù hợp ở bước thêm giỏ. Giá và tồn kho được kiểm tra lại.',
        style: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
    ],
    OutlinedButton(
      onPressed: () => setState(() {
        result = null;
        error = '';
      }),
      child: const Text('Điều chỉnh nhu cầu'),
    ),
  ];
}

class _PhotoTip extends StatelessWidget {
  const _PhotoTip({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title, text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      Icon(icon, size: 22, color: AppColors.primary),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    ],
  );
}
