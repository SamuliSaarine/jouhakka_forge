class Resolution {
  final double width;
  final double height;
  final double ratio;

  const Resolution({required this.width, required this.height})
      : ratio = width / height;

  static const Resolution fullHD = Resolution(width: 1920, height: 1080);

  static const Resolution ipad10 = Resolution(width: 820, height: 1180);

  static const Resolution iphone13 = Resolution(width: 390, height: 844);
}
