import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

typedef SubscriptionMutationGuard =
    Future<GraphQLError?> Function(Set<String> fields);

/// Inspect root fields (including fragments and aliases) so a different operation
/// name cannot bypass the write guard. Backend enforcement remains authoritative.
Set<String> mutationRootFields(Request request) {
  final document = request.operation.document;
  final fragments = {
    for (final f in document.definitions.whereType<FragmentDefinitionNode>())
      f.name.value: f,
  };
  final roots = <String>{};
  void visit(SelectionSetNode selections, Set<String> seen) {
    for (final node in selections.selections) {
      if (node is FieldNode && node.name.value != '__typename') {
        roots.add(node.name.value);
      }
      if (node is InlineFragmentNode) visit(node.selectionSet, seen);
      if (node is FragmentSpreadNode && seen.add(node.name.value)) {
        final fragment = fragments[node.name.value];
        if (fragment != null) visit(fragment.selectionSet, seen);
      }
    }
  }

  for (final operation
      in document.definitions.whereType<OperationDefinitionNode>()) {
    if (request.operation.operationName != null &&
        operation.name?.value != request.operation.operationName) {
      continue;
    }
    if (operation.type == OperationType.mutation) {
      visit(operation.selectionSet, <String>{});
    }
  }
  return roots;
}

class PosSubscriptionRequestScope extends ContextEntry {
  const PosSubscriptionRequestScope(this.scope);
  final String scope;
  @override
  List<Object?> get fieldsForEquality => [scope];
}

Link posSubscriptionLink(
  SubscriptionMutationGuard? Function() readGuard,
  String Function() readScope,
) => Link.function((request, [forward]) async* {
  final roots = mutationRootFields(request);
  final guard = readGuard();
  if (guard != null && roots.isNotEmpty) {
    final denied = await guard(roots);
    if (denied != null) {
      yield Response(errors: [denied], response: const {});
      return;
    }
  }
  if (forward != null) {
    yield* forward(
      request.withContextEntry(PosSubscriptionRequestScope(readScope())),
    );
  }
});
