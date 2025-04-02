# Audiobook Converter

A bash script that converts a folder of MP3 files into a single M4B audiobook file with proper chapter markers.

## Features

- Automatically creates an M4B audiobook from a folder of MP3 files
- Preserves the original audio quality
- Creates chapter markers for each source file with accurate timestamps
- Uses filenames as chapter titles
- Maintains file order using natural sorting
- Supports custom output filenames

## Requirements

- Bash shell
- FFmpeg and FFprobe (usually installed together)
- bc (Basic Calculator - standard on most Unix/Linux systems)

## Installation

1. Download the `audiobook_converter` script
2. Make it executable:
   ```bash
   chmod +x audiobook_converter
   ```
3. Place it somewhere in your PATH or use it from its current location

## Usage

```bash
./audiobook_converter <folder_path> [output_filename]
```

### Parameters

- `<folder_path>`: Path to the directory containing the MP3 files (required)
- `[output_filename]`: Name for the output M4B file (optional, defaults to "output.m4b")

### Examples

Convert a folder of MP3s using the default output name:
```bash
./audiobook_converter "/path/to/my/audiobook/files"
```

Convert a folder of MP3s with a custom output name:
```bash
./audiobook_converter "/path/to/my/audiobook/files" "Great Expectations"
```
This will create "Great Expectations.m4b" (.m4b extension is added automatically if missing)

## How It Works

1. The script scans the specified folder for MP3 files
2. It calculates the duration of each MP3 file using FFprobe
3. It generates chapter metadata with proper timestamps based on the duration of each file
4. It uses FFmpeg to combine all MP3 files into a single M4B file with chapter markers
5. The resulting M4B file can be played in audiobook apps with chapter navigation

## Notes

- MP3 files are sorted alphabetically; use consistent naming to ensure proper order
- Original MP3 files are not modified
- The script must be run from a location with write permissions
- Temporary files are cleaned up after successful conversion

## Troubleshooting

- If the script fails with "command not found", make sure FFmpeg and FFprobe are installed
- If chapter markers aren't appearing, ensure your audiobook player supports M4B chapter navigation
- For very large audiobooks or many files, the conversion process may take some time

