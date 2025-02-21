part of 'page_design_view.dart';

extension _PageDesignViewExtension on _PageDesignViewState {
  void _onKeyEvent(KeyEvent event) {
    try {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.altLeft:
          _extraPaddingKeyEvent(event);
          break;
        case LogicalKeyboardKey.delete:
          if (Session.selectedElement.value != null &&
              Session.selectedElement.value!.root == widget.page) {
            UIElement selectedElement = Session.selectedElement.value!;
            if (selectedElement.parent == null) {
              debugPrint("Cannot delete element without parent");
              return;
            }
            selectedElement.parent!.removeChild(selectedElement);
          }
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint("Error in key event: $e");
    }
  }

  void _extraPaddingKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      debugPrint("Alt Down");
      if (_lastTimeShiftDown != null &&
          DateTime.now().difference(_lastTimeShiftDown!) <
              const Duration(milliseconds: 500)) {
        _containerEditorController.toggle();
      } else {
        _containerEditorController.hold();
      }
      _lastTimeShiftDown = DateTime.now();
    } else if (event is KeyUpEvent) {
      debugPrint("Alt Up");
      _containerEditorController.release();
    }
  }

  void _updateResolution(Resolution resolution) {
    UIElement body = widget.page.body;
    body.width.value = resolution.width;
    body.height.value = resolution.height;
    setState(() {
      Session.currentResolution.value = resolution;
    });
  }
}
