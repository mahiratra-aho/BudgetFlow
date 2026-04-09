// pour l'inscription
class ModeleInscription {
  const ModeleInscription({
    this.pseudo = '',
    this.email = '',
    this.motDePasse = '',
    this.confirmationMotDePasse = '',
    this.accepteConditions = false,
  });

  final String pseudo;
  final String email;
  final String motDePasse;
  final String confirmationMotDePasse;
  final bool accepteConditions;
  // composants
  ModeleInscription copieAvec({
    String? pseudo,
    String? email,
    String? motDePasse,
    String? confirmationMotDePasse,
    bool? accepteConditions,
  }) {
    return ModeleInscription(
      pseudo: pseudo ?? this.pseudo,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      confirmationMotDePasse:
          confirmationMotDePasse ?? this.confirmationMotDePasse,
      accepteConditions: accepteConditions ?? this.accepteConditions,
    );
  }
}
