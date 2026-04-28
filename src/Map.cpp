#include "Map.hpp"

Map::Map() {
    initGrid();
    initCamps();
}

Cell Map::getCell(int x, int y) const {
    return grid[x][y];
}

std::vector<Camp>& Map::getCamps() {
    return camps;
}

Camp* Map::getCampAt(int x, int y) {
    for (Camp& camp : camps) {
        if (camp.x == x && camp.y == y)
            return &camp;
    }
    return nullptr;
}

void Map::initGrid() {
    // Tout est plaine par défaut
    for (int x = 0; x < COLS; x++)
        for (int y = 0; y < ROWS; y++)
            grid[x][y] = {CellType::PLAIN};

    // --- Rivière centrale (colonne 5) ---
    // Un pont laisse passer à y=2 (seul point de passage en phase 2)
    for (int y = 0; y < ROWS; y++) {
        if (y != 2)
            grid[5][y] = {CellType::WATER};
    }

    // --- Forêts décoratives ---
    // (elles ne bloquent pas le mouvement en phase 1)
    grid[2][1] = {CellType::FOREST};
    grid[3][2] = {CellType::FOREST};
    grid[2][3] = {CellType::FOREST};
    grid[7][1] = {CellType::FOREST};
    grid[7][4] = {CellType::FOREST};
    grid[6][4] = {CellType::FOREST};
}

void Map::initCamps() {
    // Format : { x, y, ownerIndex, units, income, name }

    // --- Joueur 1 (gauche, bleu) ---
    camps.push_back({1, 1,  0, 5, 10, "Fort Bleu"});
    camps.push_back({1, 4,  0, 5, 10, "Citadelle Bleue"});

    // --- Camps neutres (milieu) ---
    // Placés de chaque côté du pont pour inciter les joueurs à se battre pour le passage
    camps.push_back({3, 3, -1, 2, 15, "Carrefour"});
    camps.push_back({6, 2, -1, 2, 15, "Passage"});

    // --- Joueur 2 (droite, rouge) ---
    camps.push_back({8, 1,  1, 5, 10, "Fort Rouge"});
    camps.push_back({8, 4,  1, 5, 10, "Citadelle Rouge"});
}
