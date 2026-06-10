/// Represents a single entry (directory or audio file) in a browsed folder.
class FileSystemEntry {
  const FileSystemEntry({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.modifiedDate,
  });

  final String name;
  final String path;
  final bool isDirectory;
  final DateTime modifiedDate;
}
