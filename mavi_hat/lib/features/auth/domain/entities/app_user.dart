/// Domain entity representing an authenticated MaviHat user.
///
/// Full TCKN is never stored on [AppUser]; only masked identifiers are held.
class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.tcknMasked,
    required this.tcknProfileMasked,
    required this.createdAt,
    this.isPhoneVerified = true,
  });

  final String uid;
  final String email;
  final String displayName;
  final String phoneNumber;
  final String tcknMasked;
  final String tcknProfileMasked;
  final DateTime createdAt;
  final bool isPhoneVerified;

  String get firstName {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : displayName;
  }

  String get initials {
    final parts =
        displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'MH';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? tcknMasked,
    String? tcknProfileMasked,
    DateTime? createdAt,
    bool? isPhoneVerified,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      tcknMasked: tcknMasked ?? this.tcknMasked,
      tcknProfileMasked: tcknProfileMasked ?? this.tcknProfileMasked,
      createdAt: createdAt ?? this.createdAt,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }
}

