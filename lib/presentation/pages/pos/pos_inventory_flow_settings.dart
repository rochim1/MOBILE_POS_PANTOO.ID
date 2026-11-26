import 'package:flutter/material.dart';
import '../../../../domain/models/pos_inventory_flow_settings.dart';
import '../../../../domain/repositories/pos_inventory_flow_repository.dart';
import '../../../../l10n/pos_inventory_flow_copy.dart';

class PosInventoryFlowSettings extends StatefulWidget {
  final PosInventoryFlowRepository repository;
  final Future<bool> Function() onSaved;
  const PosInventoryFlowSettings({
    super.key,
    required this.repository,
    required this.onSaved,
  });
  @override
  State<PosInventoryFlowSettings> createState() =>
      _PosInventoryFlowSettingsState();
}

class _PosInventoryFlowSettingsState extends State<PosInventoryFlowSettings> {
  PosInventoryFlowSnapshot? _baseline;
  PosInventoryFlowPolicy? _draft;
  PosInventoryFlowPolicy? _movementPolicy;
  PosInventoryFlowFailure? _failure;
  String? _validation;
  bool _loading = true, _saving = false, _reloadRequired = false;
  bool _refreshPending = false, _refreshing = false, _saved = false;
  int _generation = 0;
  final _tolerance = TextEditingController();
  bool get _editable =>
      !_loading && !_saving && !_reloadRequired && _baseline?.canUpdate == true;
  bool get _needsTransit =>
      _draft?.values['use_in_transit'] == true ||
      PosInventoryFlowPolicy.ruleFields.any(
        (key) => _draft?.values[key] == 'transit',
      );
  String t(String key) => inventoryFlowText(context, key);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _generation++;
    _tolerance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_saving || _refreshing) return;
    final generation = ++_generation;
    final shouldRefresh = _reloadRequired;
    setState(() {
      _loading = true;
      _failure = null;
      _validation = null;
    });
    try {
      final snapshot = await widget.repository.load();
      if (!mounted || generation != _generation) return;
      setState(() {
        _baseline = snapshot;
        _draft = snapshot.policy;
        _movementPolicy =
            snapshot.policy.values['inventory_profile'] == 'simple'
            ? null
            : snapshot.policy;
        _tolerance.text =
            '${snapshot.policy.values['over_receipt_tolerance_percent']}';
        _loading = false;
        _reloadRequired = false;
        _saved = false;
      });
      if (shouldRefresh) await _refresh();
    } on PosInventoryFlowFailure catch (failure) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failure = failure;
        _reloadRequired = true;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failure = const PosInventoryFlowFailure(
          InventoryFlowFailureKind.connection,
        );
        _reloadRequired = true;
      });
    }
  }

  void _change(PosInventoryFlowPolicy draft) => setState(() {
    _draft = draft;
    if (draft.values['inventory_profile'] != 'simple') {
      _movementPolicy = draft;
    }
    _validation = null;
    _failure = null;
    _saved = false;
  });

  void _selectMode(String mode) {
    final current = _draft;
    if (current == null) return;
    final next = mode == 'simple'
        ? current.withProfile('simple')
        : _movementPolicy ??
              current
                  .withProfile('custom')
                  .withValue('use_store_warehouse', true)
                  .withValue('use_transfer_request', true);
    _change(next);
    _tolerance.text = '${next.values['over_receipt_tolerance_percent']}';
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    var refreshed = false;
    try {
      refreshed = await widget.onSaved();
    } catch (_) {
      /* Retry menus, never the write. */
    }
    if (!mounted) return;
    setState(() {
      _refreshing = false;
      _refreshPending = !refreshed;
    });
  }

  Future<void> _save() async {
    final baseline = _baseline, draft = _draft;
    if (!_editable ||
        baseline == null ||
        draft == null ||
        draft.patchFrom(baseline.policy).isEmpty) {
      return;
    }
    final invalid = draft.validationError(
      trackStock: baseline.trackStock,
      locations: baseline.locations,
    );
    if (invalid != null) {
      setState(() => _validation = invalid);
      return;
    }
    setState(() => _saving = true);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t('confirmTitle')),
        content: SingleChildScrollView(
          child: Text(
            '${t(draft.values['inventory_profile'] == 'simple' ? 'directChoice' : 'movementChoice')}\n\n${t('confirmBody')}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('cancel')),
          ),
          FilledButton(
            key: const Key('flow-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _saving = false);
      return;
    }
    try {
      final saved = await widget.repository.save(baseline, draft);
      // Refresh the parent even if this section was switched while saving.
      var refreshed = false;
      try {
        refreshed = await widget.onSaved();
      } catch (_) {
        /* Saved once; retry only the runtime read. */
      }
      if (!mounted) return;
      setState(() {
        _baseline = saved;
        _draft = saved.policy;
        _tolerance.text =
            '${saved.policy.values['over_receipt_tolerance_percent']}';
        _saving = false;
        _saved = true;
        _failure = null;
        _validation = null;
        _refreshPending = !refreshed;
      });
    } on PosInventoryFlowFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = failure;
        _reloadRequired = failure.requiresReload;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = const PosInventoryFlowFailure(
          InventoryFlowFailureKind.uncertain,
        );
        _reloadRequired = true;
      });
    }
  }

  Widget _message(String message, {bool error = false}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: error
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      message,
      style: TextStyle(
        color: error
            ? Theme.of(context).colorScheme.onErrorContainer
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );

  Widget _location(
    String field,
    String label,
    List<PosInventoryFlowLocation> options,
    String key,
  ) {
    final selected = _draft!.values[field] as String?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$key:$selected'),
        initialValue: selected ?? '',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: t(label),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(value: '', child: Text(t('none'))),
          for (final row in options)
            DropdownMenuItem(
              value: row.id,
              child: Text(row.name, overflow: TextOverflow.ellipsis),
            ),
          if (selected != null && !options.any((row) => row.id == selected))
            DropdownMenuItem(
              value: selected,
              enabled: false,
              child: Text(t('unavailable'), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: !_editable
            ? null
            : (value) => _change(_draft!.withValue(field, value)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseline = _baseline, draft = _draft;
    final dirty =
        baseline != null &&
        draft != null &&
        draft.patchFrom(baseline.policy).isNotEmpty;
    return PopScope(
      canPop: !_saving,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            children: [
              Text(t('title'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(t('intro')),
              const SizedBox(height: 18),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (_failure != null)
                _message(
                  _failure!.kind == InventoryFlowFailureKind.validation &&
                          _failure!.detail != null
                      ? t(_failure!.detail!)
                      : t(_failure!.kind.name),
                  error: true,
                ),
              if (_validation != null) _message(t(_validation!), error: true),
              if (_reloadRequired && !_loading)
                OutlinedButton.icon(
                  key: const Key('flow-reload'),
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: Text(t('reload')),
                ),
              if (!_loading && baseline != null && draft != null) ...[
                if (!baseline.canUpdate) _message(t('readOnly')),
                DropdownButtonFormField<String>(
                  key: const Key('flow-profile'),
                  initialValue: draft.values['inventory_profile'] == 'simple'
                      ? 'simple'
                      : 'movement',
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: t('flow'),
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    for (final mode in ['simple', 'movement'])
                      DropdownMenuItem(
                        value: mode,
                        child: Text(
                          t(
                            mode == 'simple'
                                ? 'directChoice'
                                : 'movementChoice',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: !_editable
                      ? null
                      : (value) {
                          if (value != null) _selectMode(value);
                        },
                ),
                const SizedBox(height: 10),
                Text(
                  t(
                    draft.values['inventory_profile'] == 'simple'
                        ? 'simpleHelp'
                        : 'movementHelp',
                  ),
                ),
                const SizedBox(height: 18),
                KeyedSubtree(
                  key: const Key('flow-receiving'),
                  child: _location(
                    'default_receiving_location_id',
                    'receiving',
                    baseline.locations
                        .where(
                          (row) => row.canReceive(
                            allowStore:
                                draft
                                    .values['allow_direct_purchase_to_store'] ==
                                true,
                          ),
                        )
                        .toList(),
                    'receiving',
                  ),
                ),
                Text(t('locationsHelp')),
                const SizedBox(height: 12),
                if (_needsTransit)
                  _location(
                    'default_transfer_transit_location_id',
                    'transit',
                    baseline.locations.where((row) => row.isTransit).toList(),
                    'transit',
                  ),
                ExpansionTile(
                  key: const Key('flow-advanced'),
                  title: Text(t('advancedOptions')),
                  tilePadding: EdgeInsets.zero,
                  children: [
                    DropdownButtonFormField<String>(
                      key: const Key('flow-detail-profile'),
                      initialValue: draft.values['inventory_profile'],
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: t('detailProfile'),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final profile in PosInventoryFlowPolicy.profiles)
                          DropdownMenuItem(
                            value: profile,
                            child: Text(t(profile)),
                          ),
                      ],
                      onChanged: !_editable
                          ? null
                          : (value) {
                              if (value != null)
                                _change(draft.withProfile(value));
                            },
                    ),
                    const SizedBox(height: 10),
                    Text(t('${draft.values['inventory_profile']}Help')),
                    const SizedBox(height: 14),
                    for (final field in [
                      ...PosInventoryFlowPolicy.flowFlags,
                      'allow_direct_purchase_to_store',
                      'allow_over_receipt',
                    ])
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t(field)),
                        value: draft.values[field] == true,
                        onChanged: !_editable
                            ? null
                            : (value) => _change(draft.withValue(field, value)),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tolerance,
                      enabled:
                          _editable &&
                          draft.values['allow_over_receipt'] == true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t('tolerance'),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => _change(
                        draft.withValue(
                          'over_receipt_tolerance_percent',
                          double.tryParse(value.replaceAll(',', '.')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!_needsTransit)
                      _location(
                        'default_transfer_transit_location_id',
                        'transit',
                        baseline.locations
                            .where((row) => row.isTransit)
                            .toList(),
                        'transit',
                      ),
                    for (final field in PosInventoryFlowPolicy.ruleFields)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('$field:${draft.values[field]}'),
                          initialValue: draft.values[field],
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: t(field),
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            for (final rule in [
                              'system_default',
                              'direct',
                              'transit',
                            ])
                              DropdownMenuItem(
                                value: rule,
                                child: Text(
                                  t(rule == 'transit' ? 'transitRule' : rule),
                                ),
                              ),
                          ],
                          onChanged: !_editable
                              ? null
                              : (value) {
                                  if (value != null) {
                                    _change(draft.withValue(field, value));
                                  }
                                },
                        ),
                      ),
                    Text(t('routingHelp')),
                    const SizedBox(height: 16),
                  ],
                ),
                const SizedBox(height: 18),
                if (_saved || _refreshPending)
                  _message(t(_refreshPending ? 'refreshPending' : 'saved')),
                if (_refreshPending)
                  OutlinedButton.icon(
                    key: const Key('flow-refresh'),
                    onPressed: _refreshing || _saving ? null : _refresh,
                    icon: const Icon(Icons.sync),
                    label: Text(t('refresh')),
                  ),
                if (baseline.canUpdate)
                  FilledButton.icon(
                    key: const Key('flow-save'),
                    onPressed: _editable && dirty ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(t(_saving ? 'saving' : 'save')),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
