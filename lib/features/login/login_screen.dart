import 'package:boxting/data/network/auth_api.dart';
import 'package:boxting/data/repository/login_repository_impl.dart';
import 'package:boxting/data/repository/settings_repository_impl.dart';
import 'package:boxting/features/biometric/biometric_bloc.dart';
import 'package:boxting/features/biometric/biometric_screen.dart';
import 'package:boxting/features/forgot_password/forgot_password_screen.dart';
import 'package:boxting/features/home/home_screen.dart';
import 'package:boxting/features/register/register_screen.dart';
import 'package:boxting/widgets/widgets.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'login_bloc.dart';

class LoginScreen extends HookWidget {
  LoginScreen._();

  static Widget init(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LoginBloc>(
          create: (_) => LoginBloc(
            loginRepository:
                LoginRepositoryImpl(loginApi: AuthenticationApi(Dio())),
            settingsRepository: SettingsRepositoryImpl(),
          ),
        ),
        ChangeNotifierProvider<BiometricBloc>(
          create: (_) => BiometricBloc(
            SettingsRepositoryImpl(),
            LocalAuthentication(),
          ),
        )
      ],
      builder: (_, __) => LoginScreen._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _isAuthenticating = useState<bool>(false);

    final loginBloc = context.watch<LoginBloc>();
    final biometricBloc = context.watch<BiometricBloc>();

    void login(BuildContext context) async {
      if (loginBloc.usernameController.text.trim().isEmpty ||
          loginBloc.passwordController.text.trim().isEmpty) {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Ocurrio un error!",
          text: "Debe llenar los campos obligatiorios",
        );
        return;
      }

      final isFirstTimeLogin = await loginBloc.isFirstTimeLogin();
      final fingerprintLogin = await loginBloc.loadBiometricInformation();
      final loginResult = await loginBloc.login();

      if (loginBloc.failure != null) {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Ocurrio un error!",
          text: loginBloc.failure.message,
        );
      } else {
        if (loginResult) {
          if (fingerprintLogin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen.init(context)),
            );
          } else {
            if (isFirstTimeLogin) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => BiometricScreen.init(context)),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen.init(context)),
              );
            }
          }
        } else {
          CoolAlert.show(
            context: context,
            type: CoolAlertType.error,
            title: "Algo salio mal",
            text: "Error al iniciar sesión. Usuario o contraseña incorrectos.",
          );
        }
      }
    }

    void goToRegister(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterScreen.init(context),
        ));

    void authenticateBiometrical(BuildContext context) async {
      final bloc = context.read<LoginBloc>();
      final biometricLoginEnabled = await bloc.loadBiometricInformation();

      if (biometricLoginEnabled) {
        await biometricBloc.checkBiometrics();
        await biometricBloc.getAvailableBiometrics();
        if (_isAuthenticating.value)
          biometricBloc.cancelAuthentication();
        else
          biometricBloc.authenticate(
            context: context,
            onSuccess: () => CoolAlert.show(
                context: context,
                type: CoolAlertType.success,
                title: "Perfecto",
                text: "Tu huella digital ha sido validada",
                confirmBtnText: 'Continuar',
                barrierDismissible: false,
                onConfirmBtnTap: () =>
                    biometricBloc.goToHomeScreen(context, dialog: true)),
            onFailure: (PlatformException e) => CoolAlert.show(
              context: context,
              type: CoolAlertType.error,
              title: "Algo malio sal",
              text: e.message,
            ),
          );
      } else {
        CoolAlert.show(
          context: context,
          type: CoolAlertType.error,
          title: "Ocurrió un error",
          text: "Aún no has validado tu huella digital en este dispositivo.",
          confirmBtnText: 'Ok',
          onConfirmBtnTap: () => Navigator.pop(context),
        );
      }
    }

    final rememberCheckbox = useState<bool>(false);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: ListView(
          children: <Widget>[
            Image.asset(
              'assets/images/boxting_icon_white.png',
              width: 120,
              height: 120,
            ),
            SizedBox(height: 32),
            TextField(
              controller: loginBloc.usernameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: 'Usuario',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              controller: loginBloc.passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                hintText: 'Contraseña',
              ),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => goToForgotPassword(context),
              child: Text(
                'Olvide mi contraseña',
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 8),
            CheckboxListTile(
              title: Text('Recordar'),
              value: rememberCheckbox.value,
              onChanged: (bool value) => rememberCheckbox.value = value,
            ),
            FlatButton.icon(
              onPressed: () => authenticateBiometrical(context),
              icon: Icon(Icons.fingerprint_outlined),
              label: Text('Autenticación biometrica'),
            ),
            SizedBox(height: 24),
            loginBloc.loginState == LoginState.loading
                ? Center(child: CircularProgressIndicator())
                : BoxtingButton(
                    type: BoxtingButtonType.primary,
                    onPressed: () => login(context),
                    child: Text(
                      'Ingresar'.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
            SizedBox(height: 16),
            Center(
              child: InkWell(
                onTap: () => goToRegister(context),
                child: Text('Aún no tienes una cuenta? Registrate aquí'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> goToForgotPassword(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForgotPasswordScreen.init(context),
        ),
      );
}
