class QuietHoursPolicy {
  const QuietHoursPolicy();

  bool allowsNow(DateTime localNow) {
    return true;
  }
}
