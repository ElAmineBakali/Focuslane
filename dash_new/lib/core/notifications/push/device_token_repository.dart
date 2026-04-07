abstract class DeviceTokenRepository {
  Future<void> upsertToken({
    required String userId,
    required String deviceId,
    required String token,
    required String platform,
    required String appVersion,
    required String timezone,
    required DateTime updatedAtUtc,
  });

  Future<void> revokeToken({
    required String userId,
    required String deviceId,
  });
}
