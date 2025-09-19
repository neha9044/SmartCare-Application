// lib/utils/chat_status.dart
enum ChatStatus {
  pending,
  active,
  closed,
  declined,
}

extension ChatStatusExtension on ChatStatus {
  String toShortString() {
    switch (this) {
      case ChatStatus.pending:
        return 'pending';
      case ChatStatus.active:
        return 'active';
      case ChatStatus.closed:
        return 'closed';
      case ChatStatus.declined:
        return 'declined';
    }
  }

  static ChatStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ChatStatus.pending;
      case 'active':
        return ChatStatus.active;
      case 'closed':
        return ChatStatus.closed;
      case 'declined':
        return ChatStatus.declined;
      default:
        return ChatStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case ChatStatus.pending:
        return 'Pending';
      case ChatStatus.active:
        return 'Active';
      case ChatStatus.closed:
        return 'Closed';
      case ChatStatus.declined:
        return 'Declined';
    }
  }
}

// Helper functions
bool isChatActive(String status) {
  return status == ChatStatus.active.toShortString();
}

bool isChatPending(String status) {
  return status == ChatStatus.pending.toShortString();
}

bool isChatEnded(String status) {
  return status == ChatStatus.closed.toShortString() ||
      status == ChatStatus.declined.toShortString();
}