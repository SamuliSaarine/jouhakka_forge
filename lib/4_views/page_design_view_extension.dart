part of 'page_design_view.dart';

extension _PageDesignViewExtension on _PageDesignViewState {
  void _onKeyEvent(KeyEvent event) {
    try {
      if (event.logicalKey == MyControls.extraSpace) {
        _extraPaddingKeyEvent(event);
      } else if (event.logicalKey == LogicalKeyboardKey.delete) {
        if (event is KeyUpEvent) {
          _deleteEvent();
        }
      }
    } catch (e) {
      debugPrint("Error in key event: $e");
    }
  }

  void _deleteEvent() {
    if (Session.selectedElement.value != null &&
        Session.selectedElement.value!.root == widget.page) {
      UIElement selectedElement = Session.selectedElement.value!;
      if (selectedElement.parent == null) {
        debugPrint("Cannot delete element without parent");
        return;
      }
      selectedElement.parent!.removeChild(selectedElement);
    } else {
      debugPrint("No element selected in page");
    }
  }

  void _extraPaddingKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      debugPrint("Extra padding down");
      if (_lastTimePaddingDown != null &&
          DateTime.now().difference(_lastTimePaddingDown!) <
              const Duration(milliseconds: 500)) {
        _paddingController.toggle();
      } else {
        _paddingController.hold();
      }
      _lastTimePaddingDown = DateTime.now();
    } else if (event is KeyUpEvent) {
      debugPrint("Extra padding up");
      _paddingController.release();
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
