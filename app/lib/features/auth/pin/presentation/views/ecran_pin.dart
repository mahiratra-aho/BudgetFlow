import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../viewmodels/pin_viewmodel.dart';

export '../viewmodels/pin_viewmodel.dart' show ModePIN;

class EcranPin extends StatefulWidget {
  final ModePIN mode;
  final String? pinAVerifier;
  final ValueChanged<String> onSucces;
  final VoidCallback? onMotDePasseOublie;

  const EcranPin({
    super.key,
    required this.mode,
    this.pinAVerifier,
    required this.onSucces,
    this.onMotDePasseOublie,
  });

  @override
  State<EcranPin> createState() => _EtatEcranPin();
}

class _EtatEcranPin extends State<EcranPin> {
  late PinViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = PinViewModel(mode: widget.mode, pinAVerifier: widget.pinAVerifier);
    _vm.addListener(_onVmChange);
  }

  void _onVmChange() {
    setState(() {});
    if (_vm.succes) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => widget.onSucces(_vm.pinFinal ?? ''));
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChange);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondPrincipal,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppEspaces.xl),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppCouleurs.primaire.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    color: AppCouleurs.primaire, size: 36),
              ),
              const SizedBox(height: AppEspaces.lg),
              Text(_vm.titre,
                  style: AppTypographie.titleLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(_vm.sousTitre,
                  style: AppTypographie.bodyMedium
                      .copyWith(color: AppCouleurs.texteSecondaire),
                  textAlign: TextAlign.center),
              const SizedBox(height: AppEspaces.xxl),

              // Points PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final rempli = i < _vm.pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _vm.erreur
                          ? AppCouleurs.erreur
                          : rempli
                              ? AppCouleurs.primaire
                              : AppCouleurs.textePrincipal.withOpacity(0.15),
                    ),
                  );
                }),
              ),

              AnimatedOpacity(
                opacity: _vm.erreur ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('PIN incorrect, réessayez',
                      style: AppTypographie.bodySmall
                          .copyWith(color: AppCouleurs.erreur)),
                ),
              ),

              const Spacer(),

              // Clavier
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                childAspectRatio: 1.6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                  '',
                  '0',
                  '⌫',
                ].map((c) {
                  if (c.isEmpty) return const SizedBox();
                  return _BoutonPin(
                    valeur: c,
                    onTap: c == '⌫'
                        ? _vm.effacerDernier
                        : () => _vm.saisirChiffre(c),
                    estEffacer: c == '⌫',
                  );
                }).toList(),
              ),

              if (widget.onMotDePasseOublie != null)
                TextButton(
                  onPressed: widget.onMotDePasseOublie,
                  child: Text('Mot de passe oublié ?',
                      style: AppTypographie.bodySmall.copyWith(
                          color: AppCouleurs.primaire,
                          fontWeight: FontWeight.w600)),
                ),

              const SizedBox(height: AppEspaces.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonPin extends StatelessWidget {
  final String valeur;
  final VoidCallback onTap;
  final bool estEffacer;

  const _BoutonPin({
    required this.valeur,
    required this.onTap,
    this.estEffacer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRayons.md),
        child: Container(
          decoration: BoxDecoration(
            color: estEffacer
                ? AppCouleurs.erreur.withOpacity(0.1)
                : AppCouleurs.surface,
            borderRadius: BorderRadius.circular(AppRayons.md),
            boxShadow: [
              BoxShadow(
                  color: AppCouleurs.textePrincipal.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2))
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            valeur,
            style: AppTypographie.titleMedium.copyWith(
              color:
                  estEffacer ? AppCouleurs.erreur : AppCouleurs.textePrincipal,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}
