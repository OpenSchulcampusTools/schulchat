abstract class Users {
  const Users._();

  static const user1 = User(
    String.fromEnvironment('INTEGRATION_USER1'),
    String.fromEnvironment('INTEGRATION_PASSWORD1'),
  );
  static const user2 = User(
    String.fromEnvironment('INTEGRATION_USER2'),
    String.fromEnvironment('INTEGRATION_PASSWORD2'),
  );
}

class User {
  final String name;
  final String password;

  const User(this.name, this.password);
}

final homeserver = 'synapse';
