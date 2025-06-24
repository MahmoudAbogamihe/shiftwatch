import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class Location {
  final String name;
  final String imagePath;

  Location({required this.name, required this.imagePath});
}

Future<List<Location>> fetchLocationsFromAzure() async {
  final String accountName = 'gp1storage2';
  final String containerName = 'location-screens-videos';
  final String sasToken =
      'sv=2024-11-04&ss=bfqt&srt=co&sp=rwdlacupiytfx&se=2027-02-16T22:26:06Z&st=2025-05-09T13:26:06Z&spr=https,http&sig=H%2BJaeH5Yu2EBBoblfSEfn%2BHWHZCPRza1XzAdhKZYCzE%3D';

  final String url =
      'https://$accountName.blob.core.windows.net/$containerName?restype=container&comp=list&$sasToken';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('فشل تحميل قائمة الصور من Azure');
  }

  final xmlDoc = XmlDocument.parse(response.body);
  final blobs = xmlDoc.findAllElements('Blob');
  final List<Location> locations = [];

  String prettifyName(String fileName) {
    return fileName
        .split('.')
        .first
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  for (final blob in blobs) {
    final nameElement = blob.findElements('Name').first.text;
    final imageUrl =
        'https://$accountName.blob.core.windows.net/$containerName/$nameElement';

    final displayName = prettifyName(nameElement);
    locations.add(Location(name: displayName, imagePath: imageUrl));
  }

  return locations;
}
