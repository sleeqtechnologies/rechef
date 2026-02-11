import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../cookbook_provider.dart';


class AddToCookbookSheet extends ConsumerStatefulWidget {
  const AddToCookbookSheet({
    super.key,
    required this.recipeId,
    this.currentCookbookIds,
  });

  final String recipeId;

  final List<String>? currentCookbookIds;

  static Future<void> show(
    BuildContext context, {
    required String recipeId,
    List<String>? currentCookbookIds,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => AddToCookbookSheet(
        recipeId: recipeId,
        currentCookbookIds: currentCookbookIds,
      ),
    );
  }

  @override
  ConsumerState<AddToCookbookSheet> createState() =>
      _AddToCookbookSheetState();
}

class _AddToCookbookSheetState extends ConsumerState<AddToCookbookSheet> {
  Set<String>? _selectedIds;
  Set<String> _originalIds = {};
  bool _saving = false;
  bool _loadingIds = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentCookbookIds != null) {
      _selectedIds = Set.from(widget.currentCookbookIds!);
      _originalIds = Set.from(widget.currentCookbookIds!);
    } else {
      _loadCurrentCookbookIds();
    }
  }

  Future<void> _loadCurrentCookbookIds() async {
    setState(() => _loadingIds = true);
    try {
      final repo = ref.read(cookbookRepositoryProvider);
      final ids = await repo.fetchCookbookIdsForRecipe(widget.recipeId);
      if (mounted) {
        setState(() {
          _selectedIds = Set.from(ids);
          _originalIds = Set.from(ids);
          _loadingIds = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedIds = {};
          _originalIds = {};
          _loadingIds = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cookbooksAsync = ref.watch(cookbooksProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Title
                  Text(
                    'Add to Cookbook',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 12),
                  // Cookbook list
                  if (_loadingIds)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  else
                    cookbooksAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Failed to load cookbooks',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                      data: (state) {
                        final cookbooks = state.cookbooks;
                        if (cookbooks.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.menu_book_outlined,
                                    size: 48, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No cookbooks yet',
                                  style:
                                      TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create one to start organizing',
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.4,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: cookbooks.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.shade200,
                            ),
                            itemBuilder: (context, index) {
                              final cookbook = cookbooks[index];
                              final isSelected =
                                  _selectedIds?.contains(cookbook.id) ??
                                      false;
                              return _CookbookCheckRow(
                                name: cookbook.name,
                                recipeCount: cookbook.recipeCount,
                                isSelected: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    _selectedIds ??= {};
                                    if (val) {
                                      _selectedIds!.add(cookbook.id);
                                    } else {
                                      _selectedIds!.remove(cookbook.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  // Save button
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving || _loadingIds ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4F63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const CupertinoActivityIndicator(
                              color: Colors.white)
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedIds == null) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(cookbooksProvider.notifier);

      // Add to new cookbooks
      final toAdd = _selectedIds!.difference(_originalIds);
      for (final cookbookId in toAdd) {
        await notifier.addRecipesToCookbook(cookbookId, [widget.recipeId]);
      }

      // Remove from deselected cookbooks
      final toRemove = _originalIds.difference(_selectedIds!);
      for (final cookbookId in toRemove) {
        await notifier.removeRecipeFromCookbook(cookbookId, widget.recipeId);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update cookbooks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

}

// ---------------------------------------------------------------------------
// Cookbook checkbox row
// ---------------------------------------------------------------------------

class _CookbookCheckRow extends StatelessWidget {
  const _CookbookCheckRow({
    required this.name,
    required this.recipeCount,
    required this.isSelected,
    required this.onChanged,
  });

  final String name;
  final int recipeCount;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  static const _accentColor = Color(0xFFFF4F63);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isSelected),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            // Circle checkbox matching grocery list style
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _accentColor : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? SvgPicture.asset(
                      'assets/icons/check-mark.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$recipeCount ${recipeCount == 1 ? 'recipe' : 'recipes'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 13,
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
}
