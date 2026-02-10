import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/import_repository.dart';
import '../import_provider.dart';
import '../monthly_import_usage_provider.dart';
import '../pending_jobs_provider.dart';
import '../../subscription/subscription_provider.dart';

class ImportRecipeScreen extends ConsumerStatefulWidget {
  const ImportRecipeScreen({super.key, this.initialUrl, this.initialImagePath});

  final String? initialUrl;
  final String? initialImagePath;

  @override
  ConsumerState<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends ConsumerState<ImportRecipeScreen> {
  late final TextEditingController _urlController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _submitContent());
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submitContent() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    // Free users are limited to 5 imports per calendar month. We use the
    // cached monthlyImportUsageProvider value if available; if it's still
    // loading or failed, we allow the import rather than blocking.
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      final usageAsync = ref.read(monthlyImportUsageProvider);
      final usage = usageAsync.maybeWhen(
        data: (value) => value,
        orElse: () => null,
      );

      if (usage != null && usage.used >= usage.limit) {
        await ref.read(subscriptionProvider.notifier).showPaywall();
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(importRepositoryProvider);
      final result = await repo.submitContent(url);
      if (!mounted) return;

      ref.read(pendingJobsProvider.notifier).addJob(
        ContentJob(
          id: result.jobId,
          status: 'pending',
          savedContentId: result.savedContentId,
        ),
      );

      // Refresh monthly usage so any UI showing the count (e.g. the recipes
      // top bar badge) reflects the new import.
      ref.invalidate(monthlyImportUsageProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recipe is being generated in the background'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      context.go('/recipes');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.go('/recipes'),
        ),
        title: Text(
          'Import Recipe',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste a recipe URL',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          enabled: !_isSubmitting,
                          decoration: InputDecoration(
                            hintText: 'https://...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _submitContent(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitContent,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: _isSubmitting
                              ? const CupertinoActivityIndicator(radius: 10, color: Colors.white)
                              : const Text(
                                  'Import',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isSubmitting
                  ? _SubmittingView()
                  : _error != null
                      ? _ErrorView(error: _error!, onRetry: _submitContent)
                      : _EmptyView(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmittingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoActivityIndicator(
            radius: 16,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Submitting...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Try again',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Paste a recipe link to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
