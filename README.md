# Mechanix Music

Music App lets you browse, manage, and play your music tracks, built with Flutter Elinux for Mechanix OS. It provides a simple and intuitive interface for managing your music library.

## Install Guide

### Pre-requisites:

- [Flutter-Elinux SDK](https://github.com/flutter-elinux/flutter-elinux)
- [Dart SDK](https://dart.dev/get-dart)

### Steps to run Music App:

1. Clone the repository:

```bash
$ git clone https://github.com/mecha-org/mechanix-music
$ cd mechanix-music
```

2. Install Flutter dependencies:

For flutter-elinux:

```bash
$ flutter-elinux pub get
```

3. Run the Application:

For flutter-elinux:

```bash
$ flutter-elinux run
```

## Testing

### Run Unit & BLoC Tests

```bash
flutter-elinux test
```

### Run Integration Tests

```bash
flutter-elinux test integration_test/<test-file-name>
```

## Key Features

- **Real-Time Library Syncing**: Scans your default `~/Music` directory automatically at startup and watches for real-time filesystem changes (add, delete, rename, or move) to keep library up-to-date.
- **Custom Storage Imports**: Import audio tracks from external storage devices or target custom directories directly into your local library database.
- **File & Folder Navigator**: Browse system-wide directories using a built-in file explorer to play tracks directly or add entire folders.
- **Metadata Extraction**: Reads song metadata (title, artist, album, duration) automatically using robust metadata readers to organize your tracks.
- **Full Playback Suite**: Complete playback control (play, pause, resume, seek, next, previous)
