import 'package:flutter/material.dart';
import 'package:speed_ios/model/car.category.new.model.dart';
import 'package:speed_ios/ui/widgets/lists/item_choose_car_widget.dart';

Widget _buildCarCategory(BuildContext context, CarCategoryNewModel model,
    String selectedId, Function() onTap) {
  return ListView.builder(
    itemCount: model.carCategory!.length,
    itemBuilder: (context, index) {
      CarCategory item = model.carCategory![index];
      return CarCategoryItem(
          id: "${item.id}",
          selectedId: selectedId,
          title: "${item.title}",
          price: "${item.pricePerMeter}",
          photo: "${item.photo}",
          avalaible: "${item.available}",
          onTap: onTap);
    },
  );
}
