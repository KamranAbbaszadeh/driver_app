// Defines the list of widgets corresponding to each tab in the bottom navigation bar.
import 'package:onemoretour/front/displayed_items/tours/my_rides_body.dart';
import 'package:onemoretour/front/displayed_items/tours/new_orders_page.dart';
import 'package:onemoretour/front/displayed_items/profile/profile_page.dart';
import 'package:flutter/widgets.dart';

/// List of pages displayed based on the selected bottom navigation tab index.
/// Index 0: My Rides, Index 1: New Orders, Index 2: Profile Page.
List<Widget> listNavBar = [
  MyRidesBody(),
  NewOrdersPage(),
  ProfilePage(),
];
