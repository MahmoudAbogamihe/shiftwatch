class Location {
  final String name;
  final String imagePath;

  Location({required this.name, required this.imagePath});
}

final List<Location> locations = [
  Location(
      name: 'Location 1',
      imagePath:
          'https://images.pexels.com/photos/12903133/pexels-photo-12903133.jpeg'), // رابط مباشر
  Location(
      name: 'Location 2',
      imagePath:
          'https://gp1storage2.blob.core.windows.net/location-screens-videos/employeeLocationsScreenshot.png'),
  Location(
      name: 'Location 3',
      imagePath:
          'https://images.pexels.com/photos/1181401/pexels-photo-1181401.jpeg'), // رابط مباشر
];
