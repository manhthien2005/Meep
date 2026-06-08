import 'package:meep/shared/models/post.dart';

/// Resolves a caption preset for [type].
/// Each implementation returns localised, contextual text
/// (e.g. current time, location name, weather description).
abstract class CaptionService {
  Future<String> resolve(CaptionType type);
}
