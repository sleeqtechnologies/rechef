import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../cookbook_provider.dart';
import '../domain/cookbook.dart';

class CookbookListView extends ConsumerWidget {
  const CookbookListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cookbooksAsync = ref.watch(cookbooksProvider);

    return cookbooksAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Failed to load cookbooks',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(cookbooksProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) {
        // Create button + virtual cookbooks + user cookbooks = total items
        const fixedCount =
            4; // create + "All Recipes" + "Shared with Me" + "Pantry Picks"
        final userCookbooks = state.cookbooks;
        final totalItems = fixedCount + userCookbooks.length;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(cookbooksProvider);
                await ref.read(cookbooksProvider.future);
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.horizontalMargin,
                12,
                AppSpacing.horizontalMargin,
                140,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0) {
                      return _CreateCookbookCard(
                        onTap: () => _showCreateCookbookSheet(context, ref),
                      );
                    }
                    if (index == 1) {
                      return _CookbookCard(
                        name: 'All recipes',
                        recipeCount: state.allRecipesCount,
                        coverImages: state.allRecipeImages,
                        onTap: () =>
                            context.push('/cookbooks/__all_recipes__'),
                      );
                    }
                    if (index == 2) {
                      return _CookbookCard(
                        name: 'Shared with me',
                        recipeCount: state.sharedWithMeCount,
                        coverImages: state.sharedImages,
                        onTap: () =>
                            context.push('/cookbooks/__shared_with_me__'),
                      );
                    }
                    if (index == 3) {
                      return _CookbookCard(
                        name: 'Pantry Picks',
                        recipeCount: null,
                        coverImages: const [],
                        svgIcon: 'assets/icons/pantry.svg',
                        onTap: () =>
                            context.push('/cookbooks/__pantry_picks__'),
                      );
                    }

                    final cookbook = userCookbooks[index - fixedCount];
                    return _CookbookCard(
                      name: cookbook.name,
                      recipeCount: cookbook.recipeCount,
                      coverImages: cookbook.coverImages,
                      onTap: () => context.push('/cookbooks/${cookbook.id}'),
                      onLongPress: () =>
                          _showCookbookOptions(context, ref, cookbook),
                    );
                  },
                  childCount: totalItems,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateCookbookSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (ctx) => _CreateCookbookSheet(
        onSave: (name) async {
          Navigator.pop(ctx);
          await ref
              .read(cookbooksProvider.notifier)
              .createCookbook(name: name);
        },
      ),
    );
  }

  void _showCookbookOptions(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameCookbookSheet(context, ref, cookbook);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
              title: Text('Delete',
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteCookbook(context, ref, cookbook);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showRenameCookbookSheet(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreateCookbookSheet(
        initialName: cookbook.name,
        title: 'Rename Cookbook',
        buttonLabel: 'Rename',
        onSave: (name) async {
          Navigator.pop(ctx);
          await ref
              .read(cookbooksProvider.notifier)
              .updateCookbook(id: cookbook.id, name: name);
        },
      ),
    );
  }

  void _confirmDeleteCookbook(
      BuildContext context, WidgetRef ref, Cookbook cookbook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cookbook?'),
        content: Text(
          'Are you sure you want to delete "${cookbook.name}"? '
          'Recipes in this cookbook will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(cookbooksProvider.notifier)
                  .deleteCookbook(cookbook.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create / Rename bottom sheet
// ---------------------------------------------------------------------------

class _CreateCookbookSheet extends StatefulWidget {
  const _CreateCookbookSheet({
    this.initialName,
    this.title = 'New Cookbook',
    this.buttonLabel = 'Create',
    required this.onSave,
  });

  final String? initialName;
  final String title;
  final String buttonLabel;
  final Future<void> Function(String name) onSave;

  @override
  State<_CreateCookbookSheet> createState() => _CreateCookbookSheetState();
}

class _CreateCookbookSheetState extends State<_CreateCookbookSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _controller.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    await widget.onSave(name);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _handleSave(),
            decoration: InputDecoration(
              hintText: 'Cookbook name',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _saving ? null : _handleSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4F63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const CupertinoActivityIndicator(color: Colors.white)
                  : Text(
                      widget.buttonLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cookbook card with stacked/fanned images
// ---------------------------------------------------------------------------

class _CookbookCard extends StatelessWidget {
  const _CookbookCard({
    required this.name,
    required this.recipeCount,
    this.coverImages = const [],
    this.svgIcon,
    required this.onTap,
    this.onLongPress,
  });

  final String name;
  final int? recipeCount;
  final List<String> coverImages;
  final String? svgIcon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Text at top-left
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          height: 1.2,
                        ),
                  ),
                  if (recipeCount != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            // Stacked images at bottom-right
            if (coverImages.isNotEmpty)
              Positioned(
                bottom: -4,
                right: -4,
                child: _FannedImages(images: coverImages),
              )
            else
              Positioned(
                bottom: 12,
                right: 12,
                child: svgIcon != null
                    ? SvgPicture.asset(
                        svgIcon!,
                        width: 32,
                        height: 32,
                        colorFilter: ColorFilter.mode(
                          Colors.grey.shade300,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        Icons.menu_book_rounded,
                        size: 32,
                        color: Colors.grey.shade300,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fanned image stack (up to 3 images overlapping)
// ---------------------------------------------------------------------------

class _FannedImages extends StatelessWidget {
  const _FannedImages({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final count = images.length.clamp(0, 3);
    if (count == 0) return const SizedBox.shrink();

    const double imgSize = 72;

    // Rotations and offsets for each card (back to front)
    const rotations = [-0.20, -0.06, 0.12];
    const offsets = [
      Offset(-38, -12),
      Offset(-16, -6),
      Offset(6, 0),
    ];

    final startIdx = 3 - count;

    return SizedBox(
      width: imgSize + 50,
      height: imgSize + 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < count; i++)
            Positioned(
              right: -offsets[startIdx + i].dx,
              bottom: -offsets[startIdx + i].dy,
              child: Transform.rotate(
                angle: rotations[startIdx + i],
                child: Container(
                  width: imgSize,
                  height: imgSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.restaurant,
                            size: 20, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create cookbook card
// ---------------------------------------------------------------------------

class _CreateCookbookCard extends StatelessWidget {
  const _CreateCookbookCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'New Cookbook',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
