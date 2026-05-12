extension SafeArray<E> on List<E> {
  /// Safely accesses an element at [index]. Returns `null` if the index is
  /// out of bounds instead of throwing a range error.
  E? safeElement(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
