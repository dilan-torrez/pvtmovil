import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:muserpol_pvt/bloc/notification/notification_bloc.dart';
import 'package:muserpol_pvt/bloc/user/user_bloc.dart';
import 'package:muserpol_pvt/components/button.dart';
import 'package:muserpol_pvt/database/db_provider.dart';
import 'package:muserpol_pvt/model/biometric_user_model.dart';
import 'package:muserpol_pvt/model/user_model.dart';
import 'package:muserpol_pvt/provider/app_state.dart';
import 'package:muserpol_pvt/services/auth_service.dart';
import 'package:muserpol_pvt/services/service_method.dart';
import 'package:muserpol_pvt/services/services.dart';
import 'package:muserpol_pvt/utils/auth_helpers.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Enrolamiento y verificacion mediante FreeOTP (TOTP, sin SMS).
///
/// Paso 1: pide al backend un secreto TOTP (POST /auth/registerTotp) y lo
///         muestra como QR junto con el secreto en texto.
/// Paso 2: el usuario agrega el secreto a FreeOTP y escribe el codigo de
///         6 digitos, que se valida con /auth/verifyPin.
class FreeOtpLogin extends StatefulWidget {
  final Map<String, dynamic> body;
  final List<Map<String, String>>? fileIdentityCard;
  const FreeOtpLogin({super.key, required this.body, this.fileIdentityCard});

  @override
  State<FreeOtpLogin> createState() => _FreeOtpLogin();
}

/// Envuelve el JSON de verifyPin para poder reutilizar
/// AuthHelpers.initSessionUserApp (que espera `response.body`).
class _SessionResponse {
  final String body;
  _SessionResponse(this.body);
}

class _FreeOtpLogin extends State<FreeOtpLogin> {
  final PinInputController codeCtrl = PinInputController();
  bool isLoading = false;
  bool _verifying = false;

  String? messageId;
  String? secret;
  String? otpauthUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    startEnrollment();
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> startEnrollment() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final response = await serviceMethod(
      mounted,
      context,
      'post',
      widget.body,
      registerTotp(),
      false,
      true,
    );

    if (!mounted) return;

    if (response == null) {
      setState(() => isLoading = false);
      return;
    }

    final dataJson = json.decode(response.body) as Map<String, dynamic>;

    setState(() {
      isLoading = false;
      messageId = dataJson['messageId'];
      secret = dataJson['secret'];
      otpauthUrl = dataJson['otpauthUrl'];
      if (messageId == null) {
        errorMessage = dataJson['message'] ?? 'No se pudo generar el código';
      }
    });
  }

  Future<void> verifyCode(String code) async {
    if (messageId == null) return;
    // Evita doble verificacion: onCompleted y pasteCode pueden dispararse
    // casi a la vez (pegar los 6 digitos completa el campo).
    if (_verifying) return;
    _verifying = true;

    final userBloc = BlocProvider.of<UserBloc>(context, listen: false);
    final notificationBloc =
        BlocProvider.of<NotificationBloc>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final tokenState = Provider.of<TokenState>(context, listen: false);

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    final response = await serviceMethod(
      mounted,
      context,
      'post',
      {'pin': code, 'messageId': messageId},
      verifyPin(),
      false,
      true,
    );

    if (!mounted) return;

    if (response == null) {
      _verifying = false;
      setState(() => isLoading = false);
      return;
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;

    if (decoded['error'] == true) {
      _verifying = false;
      setState(() {
        isLoading = false;
        errorMessage = decoded['message'] ?? 'Código incorrecto';
      });
      return;
    }

    final dataJson = decoded['data'] as Map<String, dynamic>?;

    if (dataJson == null ||
        dataJson['apiToken'] == null ||
        dataJson['information'] == null) {
      _verifying = false;
      setState(() {
        isLoading = false;
        errorMessage = 'Respuesta inválida del servidor';
      });
      return;
    }

    await DBProvider.db.database;

    UserModel user = UserModel.fromJson({
      "api_token": dataJson["apiToken"],
      "user": dataJson["information"],
    });

    await authService.writeAuxtoken(user.apiToken!);
    tokenState.updateStateAuxToken(true);

    if (!mounted) return;
    await authService.writeUser(context, userModelToJson(user));
    userBloc.add(UpdateUser(user.user!));

    final affiliateModel = AffiliateModel(idAffiliate: user.user!.affiliateId!);
    await DBProvider.db.newAffiliateModel(affiliateModel);
    notificationBloc.add(UpdateAffiliateId(user.user!.affiliateId!));

    if (!mounted) return;

    await AuthHelpers.initSessionUserApp(
      context: context,
      response: _SessionResponse(response.body),
      userApp: UserAppMobile(
        identityCard: widget.body['username'],
        numberPhone: widget.body['cellphone'],
      ),
      user: user,
    );
  }

  /// Toma el portapapeles, extrae los digitos y completa/verifica el codigo.
  /// Util porque el campo de 6 celdas no ofrece un menu de pegado comodo.
  Future<void> pasteCode() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);

    if (!mounted) return;

    final raw = clip?.text ?? '';
    // FreeOTP y los SMS suelen copiar el codigo con espacios o guiones.
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El portapapeles no contiene un código'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final code = digits.length >= 6 ? digits.substring(0, 6) : digits;
    codeCtrl.setText(code);

    if (code.length == 6) {
      FocusScope.of(context).unfocus();
      await verifyCode(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSecret = messageId != null && otpauthUrl != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10.h),
              Center(
                child: Text(
                  'Acceso con FreeOTP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'Sin SMS: escanea el código con la app FreeOTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ),
              SizedBox(height: 20.h),
              if (isLoading && !hasSecret)
                const Center(child: CircularProgressIndicator())
              else if (hasSecret) ...[
                Center(
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    color: Colors.white,
                    child: QrImageView(
                      data: otpauthUrl!,
                      version: QrVersions.auto,
                      size: 220.w,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Si no puedes escanear, agrega el secreto manualmente:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 6.h),
                Center(
                  child: SelectableText(
                    secret ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copiar secreto'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: secret ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Secreto copiado'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    'Código de 6 dígitos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                MaterialPinField(
                  pinController: codeCtrl,
                  length: 6,
                  keyboardType: TextInputType.number,
                  // Permite pegar desde el menu del sistema (long-press)...
                  enablePaste: true,
                  // ...y ademas auto-envia al completar los 6 digitos, para no
                  // perder el codigo si cambia mientras se teclea.
                  onCompleted: (value) {
                    FocusScope.of(context).unfocus();
                    verifyCode(value);
                  },
                  theme: MaterialPinTheme(
                    // 6 celdas + 5 separaciones de 8px deben caber en el
                    // ancho disponible. Se calcula a partir del ancho de
                    // pantalla menos el padding horizontal (15.w por lado)
                    // para evitar el desborde en pantallas angostas.
                    cellSize: Size(
                      ((MediaQuery.of(context).size.width -
                              30.w -
                              (5 * 8)) /
                          6)
                          .clamp(36.0, 52.0),
                      56,
                    ),
                    spacing: 8,
                    shape: MaterialPinShape.outlined,
                    borderRadius: BorderRadius.circular(8),
                    borderColor: Colors.black,
                    focusedBorderColor: const Color(0xff419388),
                    filledBorderColor: const Color(0xff419388),
                    borderWidth: 2,
                    fillColor: Colors.transparent,
                    focusedFillColor: Colors.transparent,
                    showCursor: false,
                    animationDuration: const Duration(milliseconds: 300),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.content_paste, size: 18),
                    label: const Text('Pegar código'),
                    onPressed: isLoading ? null : pasteCode,
                  ),
                ),
              ] else ...[
                Icon(Icons.error_outline, size: 48, color: Colors.amber),
                SizedBox(height: 12.h),
                Text(
                  errorMessage ?? 'No se pudo iniciar el enrolamiento FreeOTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15.sp),
                ),
                SizedBox(height: 20.h),
                ButtonComponent(
                  text: 'Reintentar',
                  onPressed: startEnrollment,
                ),
              ],
              if (errorMessage != null && hasSecret) ...[
                SizedBox(height: 12.h),
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp, color: Colors.red),
                ),
              ],
              SizedBox(height: 24.h),
              if (hasSecret)
                ButtonComponent(
                  text: 'Verificar',
                  stateLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () {
                          final code = codeCtrl.text;
                          if (code.length == 6) {
                            verifyCode(code);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Introduzca el código de 6 dígitos'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              SizedBox(height: 20.h),
              Center(
                child: Text(
                  'Versión ${dotenv.env['version']}',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
