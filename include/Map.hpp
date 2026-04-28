#pragma once
#include <vector>
#include "Camp.hpp"

// Types de cases sur la grille
enum class CellType {
    PLAIN,   // Plaine (case normale)
    FOREST,  // Forêt (décoratif en phase 1)
    WATER    // Eau / rivière (décoratif en phase 1, bloquant en phase 2)
};

struct Cell {
    CellType type;
};

class Map {
public:
    static const int COLS      = 10;  // Nombre de colonnes de la grille
    static const int ROWS      = 6;   // Nombre de lignes de la grille
    static const int CELL_SIZE = 90;  // Taille d'une case en pixels

    Map();

    Cell              getCell(int x, int y) const;  // Retourne la case à (x, y)
    std::vector<Camp>& getCamps();                   // Liste de tous les camps
    Camp*             getCampAt(int x, int y);       // Camp à (x,y), nullptr si aucun

private:
    Cell              grid[COLS][ROWS];
    std::vector<Camp> camps;

    void initGrid();   // Définit les types de cases (plaine, forêt, eau)
    void initCamps();  // Place les camps de départ
};
