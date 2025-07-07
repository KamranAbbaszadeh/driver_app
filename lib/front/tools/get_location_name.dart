// Utility function for converting geographic coordinates to a readable location name.
import 'package:geocoding/geocoding.dart';

/// Returns a human-readable location name based on latitude and longitude.
/// Uses the `geocoding` package to reverse geocode the coordinates.
/// Falls back to 'Unknown location' or error message if geocoding fails.
Future<String> getLocationName(double latitude, double longitude) async {
  try {
    // Attempt to retrieve a list of placemarks from the provided coordinates.
    List<Placemark> placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isNotEmpty) {
      // Use the first placemark result for building location string.
      Placemark place = placemarks.first;
      String street = place.street ?? '';
      String locality = place.locality ?? '';
      String country = place.country ?? '';
      // Clean up street string by removing plus codes or unwanted patterns.
      street =
          street.replaceAll(RegExp(r'[A-Z0-9]{4}\+?[A-Z0-9]{2,}'), '').trim();

      // Construct a location name using non-empty parts.
      String locationName = [
        street,
        locality,
        country,
      ].where((part) => part.isNotEmpty).join(', ');

      // Return the location name or fallback if it's empty.
      return locationName.isNotEmpty ? locationName : 'Unknown location';
    }
    // Return fallback if no placemarks were found.
    return 'No location found';
  } catch (e) {
    // Catch and return any errors that occur during geocoding.
    return 'Error retrieving location: $e';
  }
}
