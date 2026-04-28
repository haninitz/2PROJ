# SupKontQuest — Phase 1

Jeu de stratégie tour par tour en C++ / SFML 3.

## Prérequis

| Outil | Version | Téléchargement |
|---|---|---|
| CMake | ≥ 3.16 | https://cmake.org/download/ ou via MSYS2 |
| MinGW-w64 GCC | 14.2.0 | Inclus dans CodeBlocks, ou https://winlibs.com |
| SFML | 3.0.1 (MinGW 64-bit) | https://www.sfml-dev.org/download.php |
| Ninja | any | Inclus dans MSYS2 (`pacman -S mingw-w64-x86_64-ninja`) |

## Installation de SFML

1. Télécharger **SFML-3.0.1-windows-gcc-14.2.0-mingw-64-bit.zip** sur sfml-dev.org
2. Extraire dans `C:\SFML\SFML-3.0.1\`  
   La structure doit être : `C:\SFML\SFML-3.0.1\lib\cmake\SFML\`

## Compiler le projet

Ouvrir un terminal dans le dossier du projet, puis :

```bash
# 1. Configurer (à faire une seule fois)
cmake -B build -S . -G "Ninja" ^
  -DCMAKE_C_COMPILER="C:/Program Files/CodeBlocks/MinGW/bin/gcc.exe" ^
  -DCMAKE_CXX_COMPILER="C:/Program Files/CodeBlocks/MinGW/bin/g++.exe"

# 2. Compiler
cmake --build build
```

> Si cmake n'est pas dans le PATH, utiliser le chemin complet :
> `C:\msys64\mingw64\bin\cmake.exe`

## Copier les DLL runtime (première fois uniquement)

Après la première compilation, copier ces fichiers depuis `C:\Program Files\CodeBlocks\MinGW\bin\` vers `build\` :

```
libgcc_s_seh-1.dll
libstdc++-6.dll
libwinpthread-1.dll
```

Les DLL SFML (`sfml-graphics-d-3.dll`, etc.) sont copiées automatiquement par CMake.

## Lancer le jeu

```bash
build\SupKontQuest.exe
```

## Recompiler après modification

```bash
cmake --build build
```

CMake ne recompile que les fichiers modifiés.
