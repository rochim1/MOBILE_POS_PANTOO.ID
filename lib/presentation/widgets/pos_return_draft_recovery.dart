import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/pos_return/pos_return_bloc.dart';
import '../bloc/pos_return/pos_return_event.dart';
import '../bloc/pos_return/pos_return_state.dart';

class PosReturnDraftRecovery extends StatelessWidget {
  const PosReturnDraftRecovery({super.key, this.canRecover = true});
  final bool canRecover;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PosReturnBloc, PosReturnState>(
    builder: (context, state) {
      if (state.pendingDraft == null && state.pendingDraftError.isEmpty) {
        return const SizedBox.shrink();
      }
      final busy = state.status == PosReturnStatus.loading;
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: const Color(0xFFFFF4DE),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Simpan draft retur belum terkonfirmasi',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  state.pendingDraftError.isNotEmpty
                      ? state.pendingDraftError
                      : 'Invoice ${state.pendingDraft?['sumber_no'] ?? state.pendingDraft?['sumber_id']}. Pulihkan isian yang sudah dikirim sebelum membuat retur lain. Ini tidak mengajukan atau membayar refund.',
                ),
                if (canRecover &&
                    state.pendingDraft != null &&
                    state.pendingDraftError.isEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: busy
                          ? null
                          : () => context.read<PosReturnBloc>().add(
                              const RecoverReturnDraft(),
                            ),
                      icon: busy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.restore),
                      label: Text(
                        busy ? 'Memastikan draft...' : 'Pulihkan draft retur',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
