import 'package:accountify/core/providers/transaction_metadata_prompt_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('queues one active prompt at a time', () {
    final controller = TransactionMetadataPromptController();

    controller.enqueue(10);
    controller.enqueue(20);

    expect(controller.state.activeTransactionId, 10);
    expect(controller.state.pendingTransactionIds, [20]);

    controller.completeActivePrompt();

    expect(controller.state.activeTransactionId, 20);
    expect(controller.state.pendingTransactionIds, isEmpty);
  });

  test('does not duplicate the same transaction when re-queued', () {
    final controller = TransactionMetadataPromptController();

    controller.enqueue(10);
    controller.enqueue(20);
    controller.enqueue(10);
    controller.enqueue(20);

    expect(controller.state.activeTransactionId, 10);
    expect(controller.state.pendingTransactionIds, [20]);
  });
}
