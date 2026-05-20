import 'package:accountify/core/providers/database_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionMetadataBottomSheet extends ConsumerStatefulWidget {
  final int transactionId;
  final String title;
  final String subtitle;
  final List<String> predefinedTags;

  const TransactionMetadataBottomSheet({
    super.key,
    required this.transactionId,
    required this.title,
    required this.subtitle,
    required this.predefinedTags,
  });

  @override
  ConsumerState<TransactionMetadataBottomSheet> createState() =>
      _TransactionMetadataBottomSheetState();
}

class _TransactionMetadataBottomSheetState
    extends ConsumerState<TransactionMetadataBottomSheet> {
  final _reasonController = TextEditingController();
  final _customTagController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _reasonController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  void _addCustomTag() {
    final value = _customTagController.text.trim().toLowerCase();
    if (value.isEmpty) return;
    setState(() {
      _selectedTags.add(value);
      _customTagController.clear();
    });
  }

  Future<void> _save() async {
    final repository = ref.read(bankRepositoryProvider);
    final trimmedReason = _reasonController.text.trim();

    await repository.saveTransactionMetadata(
      transactionId: widget.transactionId,
      reason: trimmedReason.isEmpty ? null : trimmedReason,
      tags: _selectedTags.toList(),
    );

    if (trimmedReason.isEmpty) {
      await repository.saveAutomaticReasonIfMissing(widget.transactionId);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _skip() async {
    final repository = ref.read(bankRepositoryProvider);
    await repository.saveAutomaticReasonIfMissing(widget.transactionId);
    if (mounted) {
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add transaction details',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(widget.title, style: Theme.of(context).textTheme.bodyLarge),
          Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in widget.predefinedTags)
                FilterChip(
                  label: Text(tag),
                  selected: _selectedTags.contains(tag),
                  onSelected: (_) {
                    setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                ),
              for (final tag in _selectedTags.where(
                (tag) => !widget.predefinedTags.contains(tag),
              ))
                Chip(label: Text(tag)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('custom-tag-field'),
                  controller: _customTagController,
                  decoration: const InputDecoration(
                    labelText: 'Custom tag',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addCustomTag(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomTag,
                child: const Text('Add tag'),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _skip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
