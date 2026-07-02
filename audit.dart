// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final dir = Directory('lib');
  int fileCount = 0;
  int lineCount = 0;
  int letterCount = 0;

  void processDirectory(Directory directory) {
    for (final entity in directory.listSync()) {
      if (entity is Directory) {
        processDirectory(entity);
      } else if (entity is File && entity.path.endsWith('.dart')) {
        fileCount++;
        final content = entity.readAsStringSync();
        lineCount += content.split('\n').length;
        letterCount += content.length;
      }
    }
  }

  processDirectory(dir);

  print('AUDIT COMPLETE');
  print('Total Dart Files: $fileCount');
  print('Total Lines of Code: $lineCount');
  print('Total Letters/Characters: $letterCount');
}
