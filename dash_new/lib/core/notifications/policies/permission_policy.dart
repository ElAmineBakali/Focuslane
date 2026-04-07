class PermissionPolicy {
  const PermissionPolicy();

  Future<bool> canNotify() async {
    return true;
  }
}
