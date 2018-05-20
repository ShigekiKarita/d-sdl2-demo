Param([switch]$clean)

if ($clean) {
   rm *.txt
   rm *.zip
   rm *.dll
   exit 0
}

if (!(Test-Path SDL2.dll)) {
   curl -o SDL2.zip https://www.libsdl.org/release/SDL2-2.0.8-win32-x64.zip
   7z e SDL2.zip
}

if (!(Test-Path SDL2_image.dll)) {
   curl -o SDL2_image.zip https://www.libsdl.org/projects/SDL_image/release/SDL2_image-2.0.3-win32-x64.zip
   7z e SDL2_image.zip
}
