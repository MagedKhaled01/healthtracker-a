import 'package:flutter/foundation.dart';

mixin SelectionViewModelMixin<T> on ChangeNotifier {
  final Set<T> _selectedIds = {};
  bool _isSelectionMode = false;

  Set<T> get selectedIds => _selectedIds;
  bool get isSelectionMode => _isSelectionMode;

  int get selectedCount => _selectedIds.length;

  void toggleSelection(T id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIds.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void selectAll(List<T> allIds) {
    _selectedIds.addAll(allIds);
    _isSelectionMode = true;
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  bool isSelected(T id) => _selectedIds.contains(id);
}
