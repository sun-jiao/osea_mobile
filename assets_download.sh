#!/bin/bash

file_urls=(
    "https://github.com/sun-jiao/osea_mobile/releases/download/assets/avonet.db"
    "https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_info.json"
    "https://github.com/sun-jiao/osea_mobile/releases/download/assets/bird_model.onnx"
    "https://github.com/sun-jiao/osea_mobile/releases/download/assets/ssd_mobilenet.onnx"
)

dirs=(
    "./assets/db"
    "./assets/labels"
    "./assets/models"
    "./assets/models"
)

download_file() {
    local url="$1"
    local directory="$2"
    local filename=$(basename "$url")
    local filepath="$directory/$filename"

    mkdir -p "$directory"

    echo "Downloading $filename to $directory..."
    if curl -o "$filepath" -L "$url"; then
        echo "Downloaded $filename successfully!"
    else
        echo "Failed to download $filename."
    fi
}

for (( i = 0; i < 4; i++ )); do
    url="${file_urls[i]}"
    directory="${dirs[i]}"
    download_file "$url" "$directory"
done

echo "All files downloaded to their respective directories."