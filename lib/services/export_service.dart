import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';

class ExportService {
  Future<String> generateStudentListCsv(
    List<Map<String, dynamic>> students,
  ) async {
    List<List<dynamic>> rows = [];

    // Header
    rows.add([
      'Name',
      'Student ID',
      'Branch',
      'Current Year',
      'Email',
      'Phone',
      'Passout Year',
    ]);

    // Data
    for (var s in students) {
      rows.add([
        s['name'] ?? 'N/A',
        s['studentId'] ?? 'N/A',
        s['branch'] ?? 'N/A',
        s['currentYear'] ?? 'N/A',
        s['email'] ?? 'N/A',
        s['phone'] ?? 'N/A',
        s['passoutYear'] ?? 'N/A',
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path =
        '${directory.path}/students_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final file = File(path);
    await file.writeAsString(csv);

    return path;
  }
}
