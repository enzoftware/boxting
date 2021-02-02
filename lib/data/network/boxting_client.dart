import 'package:boxting/data/network/request/forgot_password/forgot_password_request.dart';
import 'package:boxting/data/network/request/login_request/login_request.dart';
import 'package:boxting/data/network/request/new_password_request/new_password_request.dart';
import 'package:boxting/data/network/request/register_request/register_request.dart';
import 'package:boxting/data/network/request/validate_token_request/validate_token_request.dart';
import 'package:boxting/data/network/response/default_response/default_response.dart';
import 'package:boxting/data/network/response/dni_response/dni_response.dart';
import 'package:boxting/data/network/response/login_response/login_response.dart';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'response/register_response/register_response.dart';

part 'boxting_client.g.dart';

@RestApi(baseUrl: 'https://boxting-rest-api.herokuapp.com')
abstract class BoxtingClient {
  factory BoxtingClient(Dio dio, {String baseUrl}) = _BoxtingClient;

  @POST('/login/voter')
  Future<LoginResponse> login(@Body() LoginRequest loginRequest);

  @POST('/login/register/voter')
  Future<RegisterResponse> register(@Body() RegisterRequest registerRequest);

  @GET('/login/dni/{dni}')
  Future<DniResponse> getDniInformation(@Path('dni') String dni);

  @POST('/login/forgot/password')
  Future<DefaultResponse> sendForgotPassword(
    @Body() ForgotPasswordRequest forgotPasswordRequest,
  );

  @POST('/login/validate/password-token')
  Future<DefaultResponse> validatePasswordToken(
    @Body() ValidateTokenRequest validateTokenRequest,
  );

  @POST('/login/set/password')
  Future<DefaultResponse> setNewPassword(
    @Body() NewPasswordRequest newPasswordRequest,
  );
}
