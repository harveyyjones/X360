abstract class BasePreferences {
  final String occupation;

  BasePreferences({
    required this.occupation,
  });

  Map<String, dynamic> toMap();
}
