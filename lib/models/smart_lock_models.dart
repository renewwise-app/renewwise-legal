/// What RenewWise protects with Smart Lock.
enum SmartLockScope {
  documentsOnly('Lock Documents Only'),
  appOnly('Lock App Only'),
  both('Lock Both');

  const SmartLockScope(this.label);
  final String label;

  bool get locksApp => this == SmartLockScope.appOnly || this == SmartLockScope.both;

  bool get locksDocuments =>
      this == SmartLockScope.documentsOnly || this == SmartLockScope.both;
}

/// Preferred device authentication method.
enum SmartLockAuthMethod {
  fingerprint('Fingerprint'),
  faceUnlock('Face Unlock'),
  deviceScreenLock('Device Screen Lock');

  const SmartLockAuthMethod(this.label);
  final String label;

  bool get preferBiometric =>
      this == SmartLockAuthMethod.fingerprint ||
      this == SmartLockAuthMethod.faceUnlock;
}

/// When the app should require authentication after backgrounding.
enum SmartLockAutoLock {
  immediately('Immediately', 0),
  after1Minute('After 1 Minute', 1),
  after5Minutes('After 5 Minutes', 5),
  never('Never', -1);

  const SmartLockAutoLock(this.label, this.minutes);
  final String label;

  /// Minutes in background before lock; `-1` disables auto lock.
  final int minutes;
}
