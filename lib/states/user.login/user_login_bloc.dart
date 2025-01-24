import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speed_ios/api/auth.service.dart';
import 'package:speed_ios/model/user.login.model.dart';

part 'user_login_event.dart';
part 'user_login_state.dart';

class UserLoginBloc extends Bloc<UserLoginEvent, UserLoginState> {
  AuthService authService;

  UserLoginBloc(UserLoginState userLoginState, this.authService)
      : super(userLoginState) {
    on<UserLoginEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(UserLoginInitial());
      } else {
        if (event is HandleUSerLogin) {
          emit(UserLoginLoading());
          UserLoginModel model;
          model =
              await authService.postClientLogin(event.email, event.password);
          if (model.status) {
            emit(UserLoginSuccess(userLoginModel: model));
          } else {
            emit(UserLoginError(message: model.message.toString()));
          }
        }
      }
    });
  }
}
