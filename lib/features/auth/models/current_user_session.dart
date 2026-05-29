import '../../account/models/profile.dart';
import '../../account/models/user.dart';
import '../../pairing/models/couple_relationship.dart';

class CurrentUserSession {
  final User? user;
  final Profile? profile;
  final CoupleRelationship? relationship;
  final User? partner;
  final bool isAuthenticated;

  const CurrentUserSession({
    this.user,
    this.profile,
    this.relationship,
    this.partner,
    this.isAuthenticated = false,
  });

  bool get isPaired => relationship?.isActive == true && partner != null;
  bool get isProfileCompleted => profile?.isCompleted == true;

  CurrentUserSession copyWith({
    User? user,
    Profile? profile,
    CoupleRelationship? relationship,
    User? partner,
    bool? isAuthenticated,
    bool clearRelationship = false,
    bool clearPartner = false,
  }) {
    return CurrentUserSession(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      relationship: clearRelationship ? null : relationship ?? this.relationship,
      partner: clearPartner ? null : partner ?? this.partner,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  static const empty = CurrentUserSession();
}
