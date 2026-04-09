import 'package:focuslane/core/notifications/models/notification_envelope.dart';

class PolicyDecision {
  const PolicyDecision({
    required this.allowed,
    required this.reasons,
    required this.transformedEnvelope,
  });

  final bool allowed;
  final List<String> reasons;
  final NotificationEnvelope transformedEnvelope;
}

abstract class NotificationPolicyEngine {
  Future<PolicyDecision> evaluate(NotificationEnvelope envelope);
}

class AllowAllNotificationPolicyEngine implements NotificationPolicyEngine {
  @override
  Future<PolicyDecision> evaluate(NotificationEnvelope envelope) async {
    return PolicyDecision(
      allowed: true,
      reasons: const [],
      transformedEnvelope: envelope,
    );
  }
}

