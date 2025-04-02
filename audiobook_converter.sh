#!/bin/bash
# Script to merge MP3 files into an M4B audiobook with proper chapters

# Check for arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <folder_path> [output_filename]"
    echo "       If output filename is not specified, 'output.m4b' will be used"
    exit 1
fi

FOLDER="$1"
# Check for optional second argument (output filename)
if [ -n "$2" ]; then
    OUTPUT="$2"
    # Add .m4b extension if not present
    if [[ "$OUTPUT" != *.m4b ]]; then
        OUTPUT="${OUTPUT}.m4b"
    fi
else
    OUTPUT="output.m4b"
fi
CHAPTERS_FILE="chapters.txt"
FILELIST="filelist.txt"
TEMP_INFO="temp_duration_info.txt"

# Navigate to the given folder
if [ ! -d "$FOLDER" ]; then
    echo "Error: Directory $FOLDER does not exist."
    exit 1
fi

cd "$FOLDER" || exit 1

# Clean up previous files
rm -f "$CHAPTERS_FILE" "$FILELIST" "$TEMP_INFO"

# First pass: gather all files and their durations
echo "Gathering file information..."
find . -type f -name "*.mp3" | sort > "$FILELIST"

if [ ! -s "$FILELIST" ]; then
    echo "No MP3 files found in $FOLDER."
    exit 1
fi

# Process each file to get duration information
while IFS= read -r f; do
    fullpath=$(realpath "$f")
    # More reliable duration extraction using ffprobe
    duration_sec=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$fullpath")
    
    # Round to milliseconds for chapter markers
    duration_ms=$(printf "%.3f" "$duration_sec")
    
    # Extract filename without extension for chapter name
    chapter_name=$(basename "$f" .mp3)
    
    # Store file path and duration
    echo "$fullpath|$duration_ms|$chapter_name" >> "$TEMP_INFO"
    
    # Add to filelist for ffmpeg concat
    echo "file '$fullpath'" >> "$FILELIST.tmp"
done < "$FILELIST"

mv "$FILELIST.tmp" "$FILELIST"

# Second pass: calculate timestamps and create chapter file
echo "Creating chapter metadata..."
total_files=$(wc -l < "$TEMP_INFO")
chapter_num=0
cumulative_time=0

# Create chapter file header
echo ";FFMETADATA1" > "$CHAPTERS_FILE"

while IFS='|' read -r filepath duration chapter_name; do
    chapter_num=$((chapter_num + 1))
    
    # Convert to milliseconds for integer math (Bash doesn't handle floating point)
    time_ms=$(echo "$cumulative_time * 1000" | bc | sed 's/\..*$//')
    
    # Format timestamp for chapter (HH:MM:SS.mmm)
    total_seconds=$(echo "$cumulative_time / 1" | bc)
    hours=$(printf "%02d" $(echo "$total_seconds / 3600" | bc))
    minutes=$(printf "%02d" $(echo "($total_seconds % 3600) / 60" | bc))
    seconds=$(printf "%02d" $(echo "$total_seconds % 60" | bc))
    milliseconds=$(printf "%03d" $(echo "($cumulative_time - $total_seconds) * 1000" | bc | sed 's/\..*$//'))
    
    timestamp="${hours}:${minutes}:${seconds}.${milliseconds}"
    
    # Add chapter entry
    echo "[CHAPTER]" >> "$CHAPTERS_FILE"
    echo "TIMEBASE=1/1000" >> "$CHAPTERS_FILE"
    echo "START=${time_ms}" >> "$CHAPTERS_FILE"
    
    # Calculate end time for this chapter
    cumulative_time=$(echo "$cumulative_time + $duration" | bc)
    end_time_ms=$(echo "$cumulative_time * 1000" | bc | sed 's/\..*$//')
    
    echo "END=${end_time_ms}" >> "$CHAPTERS_FILE"
    echo "title=$chapter_name" >> "$CHAPTERS_FILE"
    
    echo "Chapter $chapter_num: $chapter_name at $timestamp"
done < "$TEMP_INFO"

# Merge files into M4B with proper chapters
echo "Creating M4B file with $(wc -l < "$FILELIST") audio files and $chapter_num chapters..."
ffmpeg -f concat -safe 0 -i "$FILELIST" -i "$CHAPTERS_FILE" -map 0 -map_metadata 1 \
       -c copy -metadata title="Audiobook" \
       -metadata:s:a:0 title="Audiobook" \
       -f mp4 "$OUTPUT"

# Verify the output file exists
if [ -f "$OUTPUT" ]; then
    echo "M4B file created successfully: $OUTPUT ($(du -h "$OUTPUT" | cut -f1))"
    # Clean up
    rm -f "$CHAPTERS_FILE" "$FILELIST" "$TEMP_INFO"
else
    echo "Error: Failed to create M4B file."
    exit 1
fi
