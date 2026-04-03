cmake_minimum_required(VERSION 3.16)
project(SupKontQuest VERSION 1.0)

set(CMAKE_CXX_STANDARD 17)

# ─── SFML 3 (pré-compilé MinGW 64-bit) ───────────────────────────────────────
set(SFML_DIR "C:/SFML/SFML-3.0.1/lib/cmake/SFML")
find_package(SFML 3 COMPONENTS Graphics Window System REQUIRED)

# ─── Sources ─────────────────────────────────────────────────────────────────
add_executable(SupKontQuest
    src/main.cpp
    src/Map.cpp
    src/Game.cpp
    src/Combat.cpp
)

# ─── Headers ─────────────────────────────────────────────────────────────────
target_include_directories(SupKontQuest PRIVATE include)

# ─── Lier SFML ───────────────────────────────────────────────────────────────
target_link_libraries(SupKontQuest SFML::Graphics SFML::Window SFML::System)

# ─── Copier les DLL SFML à côté de l'exe (Windows) ───────────────────────────
if(WIN32)
    add_custom_command(TARGET SupKontQuest POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            $<TARGET_RUNTIME_DLLS:SupKontQuest>
            $<TARGET_FILE_DIR:SupKontQuest>
        COMMAND_EXPAND_LISTS
    )
endif()
