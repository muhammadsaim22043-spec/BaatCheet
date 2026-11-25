abstract class Failure
{
  final String message;

  const Failure(this.message);
}

/// Used when reading/writing data to the phone's internal storage fails.
class CacheFailure extends Failure
{
  const CacheFailure(super.message);
}

/// Used when something goes wrong during account registration or login.
class AuthFailure extends Failure
{
  const AuthFailure(super.message);
}
