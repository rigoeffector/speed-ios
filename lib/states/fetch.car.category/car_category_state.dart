// ignore_for_file: public_member_api_docs, sort_constructors_first, must_be_immutable

part of 'car_category_bloc.dart';

abstract class CarCategoryState extends Equatable {
  const CarCategoryState();

  @override
  List<Object> get props => [];
}

class CarCategoryInitial extends CarCategoryState {}

class CarCategoryLoading extends CarCategoryState {}

class CarCategorySuccess extends CarCategoryState {
  CarCategoryNewModel carCategoryModel;
  CarCategorySuccess({
    required this.carCategoryModel,
  });
}

class CarCategoryError extends CarCategoryState {
  String message;
  CarCategoryError({
    required this.message,
  });
}
