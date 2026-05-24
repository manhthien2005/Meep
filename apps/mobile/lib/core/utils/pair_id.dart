/// Returns a deterministic pair ID for two user UIDs.
/// Always `min_uid + '_' + max_uid` so the same pair always yields the same ID.
String pairIdOf(String a, String b) {
  return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
}
