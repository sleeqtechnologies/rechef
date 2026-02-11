import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cookbook_provider.dart';
import '../domain/cookbook.dart';

class AddToCookbookSheet extends ConsumerStatefulWidget {
  const AddToCookbookSheet({
    super.key,
    required this.recipeId,
    this.currentCookbookIds,
  });

  final String recipeId;

  /// If null, the sheet will fetch them from the API automatically.
  final List<String>? currentCookbookIds;

  static Future<void> show(
    BuildContext context, {
    required String recipeId,
    List<String>? currentCookbookIds,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add to Cookbook',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showCreateDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create one to start organizing',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cookbooks.length,
                      itemBuilder: (context, index) {
                        final cookbook = cookbooks[index];
                        final isSelected =
                            _selectedIds?.contains(cookbook.id) ?? false;
                        return CheckboxListTile(
                          title: Text(cookbook.name),
                          subtitle: Text(
                            '${cookbook.recipeCount} ${cookbook.recipeCount == 1 ? 'recipe' : 'recipes'}',
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              _selectedIds ??= {};
                              if (val == true) {
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
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: FilledButton(
                onPressed: _saving || _loadingIds ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4F63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
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

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Cookbook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Cookbook name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final cookbook = await ref
                  .read(cookbooksProvider.notifier)
                  .createCookbook(name: name);
              if (mounted) {
                setState(() {
                  _selectedIds ??= {};
                  _selectedIds!.add(cookbook.id);
                });
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
