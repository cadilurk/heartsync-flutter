import '../../account/models/profile.dart';
import '../../account/models/user.dart';
import '../../pairing/models/couple_relationship.dart';

class CurrentUserSession {
  final User? user;
  final Profile? profile;
  final CoupleRelationship? relationship;
  final User? partner;
  final Profile? partnerProfile;
  final bool isAuthenticated;

  const CurrentUserSession({
    this.user,
    this.profile,
    this.relationship,
    this.partner,
    this.partnerProfile,
    this.isAuthenticated = false,
  });

  bool get isPaired => relationship?.isActive == true && partner != null;
  bool get isProfileCompleted => profile?.isCompleted == true;

  /// The partner's chosen display name, or `null` if they haven't set one
  /// yet (e.g. still on profile setup) — callers should fall back to
  /// something else (email, a generic label) in that case.
  String? get partnerDisplayName {
    final name = partnerProfile?.displayName.trim();
    return name == null || name.isEmpty ? null : name;
  }

  CurrentUserSession copyWith({
    User? user,
    Profile? profile,
    CoupleRelationship? relationship,
    User? partner,
    Profile? partnerProfile,
    bool? isAuthenticated,
    bool clearRelationship = false,
    bool clearPartner = false,
  }) {
    return CurrentUserSession(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      relationship: clearRelationship ? null : relationship ?? this.relationship,
      partner: clearPartner ? null : partner ?? this.partner,
      partnerProfile: clearPartner
          ? null
          : partnerProfile ?? this.partnerProfile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  static const empty = CurrentUserSession();
}
