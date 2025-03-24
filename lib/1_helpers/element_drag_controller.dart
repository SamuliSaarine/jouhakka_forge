import 'package:jouhakka_forge/0_models/elements/ui_element.dart';
import 'package:jouhakka_forge/1_helpers/element_helper.dart';

class ElementDragController {
  UIElement? _draggedElement;
  BranchElement? _detectedParent;
  int? _detectedIndex;

  bool get isDragging => _draggedElement != null;

  void startDrag(UIElement element) {
    _draggedElement = element;
  }

  void draggedOn(BranchElement parent, int? index) {
    _detectedParent = parent;
    _detectedIndex = index;
  }

  void endDrag() {
    if (_detectedParent != null) {
      if (_detectedParent!.content.value != null && _detectedIndex != null) {
        _detectedParent!.content.value!
            .insertChild(_detectedIndex!, _draggedElement!);
      } else {
        _detectedParent!.addChild(_draggedElement!, null);
      }

      _detectedParent!.notifyListeners();
    }
  }
}
