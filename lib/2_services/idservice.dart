class IDService {
  static int index = 0;
  static Map<String, int> elementIdMap = {};

  static String newID(String prefix) {
    //get milliseconds since epoch
    int id = DateTime.now().millisecondsSinceEpoch + index;
    index++;
    if (prefix.isNotEmpty) {
      return "${prefix}_${id.toString()}";
    } else {
      return id.toString();
    }
  }

  static String newElementID(String rootId) {
    if (elementIdMap.containsKey(rootId)) {
      elementIdMap[rootId] = elementIdMap[rootId]! + 1;
    } else {
      elementIdMap[rootId] = 0;
    }
    return "${rootId}_${elementIdMap[rootId].toString()}";
  }
}
