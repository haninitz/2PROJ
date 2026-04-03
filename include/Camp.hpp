#pragma once
#include <string>

// Un camp est une base sur la carte que les joueurs peuvent contrôler
struct Camp {
    int x, y;           // Position sur la grille (en cases)
    int ownerIndex;     // -1 = neutre, 0 = Joueur 1, 1 = Joueur 2
    int units;          // Nombre d'unités présentes dans ce camp
    int income;         // Or généré par ce camp à chaque tour
    std::string name;   // Nom affiché sur la carte
};
