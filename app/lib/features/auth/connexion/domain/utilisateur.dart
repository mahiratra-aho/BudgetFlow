class Utilisateur {
  final String id;
  final String pseudo;
  final String email;
  final String? avatarUrl;
  final DateTime dateCreation;

  const Utilisateur({
    required this.id,
    required this.pseudo,
    required this.email,
    this.avatarUrl,
    required this.dateCreation,
  });

  Utilisateur copyWith({
    String? pseudo,
    String? email,
    String? avatarUrl,
  }) {
    return Utilisateur(
      id: id,
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateCreation: dateCreation,
    );
  }
}

sealed class ResultatAuth {
  const ResultatAuth();
}

class AuthSucces extends ResultatAuth {
  final Utilisateur utilisateur;
  const AuthSucces(this.utilisateur);
}

class AuthEchec extends ResultatAuth {
  final String message;
  const AuthEchec(this.message);
}
