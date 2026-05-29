import 'package:flutter_test/flutter_test.dart';

import 'package:heartsync/features/account/models/profile.dart';

void main() {
  test('profile is completed when display name is available', () {
    const profile = Profile(
      id: 'profile_1',
      userId: 'user_1',
      displayName: 'Hoang',
    );

    expect(profile.isCompleted, isTrue);
  });
}
