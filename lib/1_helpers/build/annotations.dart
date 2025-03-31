class Notifier {
  const Notifier();
}

const Notifier notifier = Notifier();

class Notify {
  const Notify();
}

const Notify notify = Notify();

class NotifyAndForward extends Notify {
  const NotifyAndForward();
}

const NotifyAndForward notifyAndForward = NotifyAndForward();

class DesignModel {
  final String description;
  const DesignModel({this.description = ""});

  String toJson() {
    return {"description": description}.toString();
  }
}

const DesignModel designModel = DesignModel();

class DesignFieldHolder {
  final List<String> fields;
  const DesignFieldHolder({this.fields = const []});

  String toJson() {
    return {"fields": fields}.toString();
  }
}

class DesignField {
  final String description;
  final String? valueRestrictions;
  final String? defaultValue;
  final bool isRequired;
  const DesignField(
      {this.description = "",
      this.defaultValue,
      this.valueRestrictions,
      this.isRequired = false});

  String toJson() {
    return {
      "description": description,
      "valueRestrictions": valueRestrictions,
      "isRequired": isRequired,
      "defaultValue": defaultValue
    }.toString();
  }
}
