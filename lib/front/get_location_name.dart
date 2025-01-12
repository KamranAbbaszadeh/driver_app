import 'package:geocoding/geocoding.dart';

Future<String> getLocationName(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      String street = place.street ?? '';
      String locality = place.locality ?? '';
      String country = place.country ?? '';
      street =
          street.replaceAll(RegExp(r'[A-Z0-9]{4}\+?[A-Z0-9]{2,}'), '').trim();

      String locationName = [
        street,
        locality,
        country,
      ].where((part) => part.isNotEmpty).join(', ');

      return locationName.isNotEmpty ? locationName : 'Unknown location';
    }
    return 'No location found';
  } catch (e) {
    return 'Error retrieving location: $e';
  }
}
