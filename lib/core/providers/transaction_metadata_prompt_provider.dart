import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class TransactionMetadataPromptState {
  final int? activeTransactionId;
  final List<int> pendingTransactionIds;

  const TransactionMetadataPromptState({
    this.activeTransactionId,
    this.pendingTransactionIds = const [],
  });

  TransactionMetadataPromptState copyWith({
    Object? activeTransactionId = _unset,
    List<int>? pendingTransactionIds,
  }) {
    return TransactionMetadataPromptState(
      activeTransactionId: identical(activeTransactionId, _unset)
          ? this.activeTransactionId
          : activeTransactionId as int?,
      pendingTransactionIds: pendingTransactionIds ?? this.pendingTransactionIds,
    );
  }
}

const Object _unset = Object();

class TransactionMetadataPromptController
    extends StateNotifier<TransactionMetadataPromptState> {
  TransactionMetadataPromptController()
      : super(const TransactionMetadataPromptState());

  void enqueue(int transactionId) {
    if (state.activeTransactionId == transactionId ||
        state.pendingTransactionIds.contains(transactionId)) {
      return;
    }

    if (state.activeTransactionId == null) {
      state = state.copyWith(activeTransactionId: transactionId);
      return;
    }

    state = state.copyWith(
      pendingTransactionIds: [...state.pendingTransactionIds, transactionId],
    );
  }

  void completeActivePrompt() {
    if (state.pendingTransactionIds.isEmpty) {
      state = const TransactionMetadataPromptState();
      return;
    }

    state = state.copyWith(
      activeTransactionId: state.pendingTransactionIds.first,
      pendingTransactionIds: state.pendingTransactionIds.sublist(1),
    );
  }

  void clear() {
    state = const TransactionMetadataPromptState();
  }
}

final transactionMetadataPromptProvider = StateNotifierProvider<
    TransactionMetadataPromptController,
    TransactionMetadataPromptState>((ref) {
  return TransactionMetadataPromptController();
});
