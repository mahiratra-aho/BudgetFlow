import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_theme.dart';

class EcranSplash extends StatefulWidget {
  final VoidCallback onTerminer;
  const EcranSplash({super.key, required this.onTerminer});

  @override
  State<EcranSplash> createState() => _EtatEcranSplash();
}

class _EtatEcranSplash extends State<EcranSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacite;
  late final Animation<double> _echelle;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _opacite = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _echelle = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();

    _attendreInitialisation();
  }

  Future<void> _attendreInitialisation() async {
    // Le travail critique est déjà fait avant runApp; on garde juste
    // un splash court pour une transition visuelle fluide.
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onTerminer();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCouleurs.fondSombre,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _opacite.value,
            child: Transform.scale(scale: _echelle.value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset('assets/icons/logo.svg',
                  width: 100, height: 100),
              const SizedBox(height: 32),
              Text(
                'BF',
                style: AppTypographie.titleLarge.copyWith(
                  color: AppCouleurs.texteInverse,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
