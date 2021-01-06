import 'package:boxting/data/repository/settings_repository_impl.dart';
import 'package:boxting/features/biometric/biometric_bloc.dart';
import 'package:boxting/features/home/home_screen.dart';
import 'package:boxting/widgets/widgets.dart';

import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

class BiometricScreen extends HookWidget {
  BiometricScreen._({this.comesFromSetting});

  final bool comesFromSetting;
  final LocalAuthentication auth = LocalAuthentication();

  static Widget init(BuildContext context, {bool settings}) {
    return ChangeNotifierProvider(
      create: (_) => BiometricBloc(repository: SettingsRepositoryImpl()),
      builder: (_, __) => BiometricScreen._(
        comesFromSetting: settings ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _isAuthenticating = useState<bool>(false);

    Future<void> _checkBiometrics() async {
      try {
        await auth.canCheckBiometrics;
      } on PlatformException catch (e) {
        print(e);
      }
    }

    void goToHomeScreen(BuildContext context, {bool dialog = false}) {
      if (comesFromSetting) {
        // Pop the dialog
        if (dialog) Navigator.pop(context);
        // Pop the Biometric Screen
        Navigator.pop(context);
      } else {
        // Pop the dialog
        if (dialog) Navigator.pop(context);
        // Go to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen.init(context),
          ),
        );
      }
    }

    Future<void> _getAvailableBiometrics() async {
      try {
        await auth.getAvailableBiometrics();
      } on PlatformException catch (e) {
        print(e);
      }
    }

    Future<void> _authenticate(BuildContext context) async {
      final bloc = context.read<BiometricBloc>();
      bool authenticated = false;
      try {
        authenticated = await auth.authenticateWithBiometrics(
          localizedReason: 'Scan your fingerprint to authenticate',
          useErrorDialogs: true,
          stickyAuth: true,
        );
        if (authenticated) {
          bloc.setBiometricInformation(authenticated);
          CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            title: "Perfecto",
            text: "Tu huella digital ha sido validada",
            confirmBtnText: 'Continuar',
            onConfirmBtnTap: () => goToHomeScreen(context, dialog: true),
          );
        } else {
          throw PlatformException(code: 'La autenticación fallo');
        }
      } on PlatformException catch (e) {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Algo salio mal",
            text: e.message,
            onConfirmBtnTap: () {
              Navigator.pop(context);
              _isAuthenticating.value = false;
            });
      }
    }

    void _cancelAuthentication() {
      auth.stopAuthentication();
    }

    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Image.asset(
                'assets/images/biometric_login.png',
                width: size.width,
                height: size.height * 0.4,
              ),
              Center(
                child: Text(
                  'Asegura tu voto utilizando tu huella digital!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Ingresa a la aplicación utilizando tu huella digital y realizado todo de manera más rapida y segura. Recuerda que puedes modificar tu accesso con huella digital dentro de Configuración > Biometria',
              ),
              SizedBox(height: 32),
              BoxtingButton(
                child: Text(
                  _isAuthenticating.value ? 'Cargando' : 'Autenticar',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
                onPressed: () async {
                  await _checkBiometrics();
                  await _getAvailableBiometrics();
                  if (_isAuthenticating.value)
                    _cancelAuthentication();
                  else
                    _authenticate(context);
                },
              ),
              SizedBox(height: 24),
              InkWell(
                onTap: () => goToHomeScreen(context),
                child: Text('Omitir por ahora'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
