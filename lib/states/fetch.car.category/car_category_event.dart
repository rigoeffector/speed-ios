part of 'car_category_bloc.dart';

abstract class CarCategoryEvent extends Equatable {
  const CarCategoryEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends CarCategoryEvent {}

class FetchCarCategoryEvent extends CarCategoryEvent {}
