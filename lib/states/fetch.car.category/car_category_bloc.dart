
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../api/auth.service.dart';
import '../../model/car.category.new.model.dart';

part 'car_category_event.dart';
part 'car_category_state.dart';

class CarCategoryBloc extends Bloc<CarCategoryEvent, CarCategoryState> {
  AuthService authService;
  CarCategoryBloc(CarCategoryState carCategoryState, this.authService) : super(carCategoryState) {
    on<CarCategoryEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(CarCategoryInitial());
      } else {
        if (event is FetchCarCategoryEvent) {
          emit(CarCategoryLoading());
          CarCategoryNewModel carCategoryModel;
          carCategoryModel =
              await authService.fetchCarCategories();
          if (carCategoryModel.status) {
            emit(CarCategorySuccess(
                carCategoryModel: carCategoryModel));
          } else {
            emit(CarCategoryError(
                message: carCategoryModel.message.toString()));
          }
        }
      }
    });
  }
}
