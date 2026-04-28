#pragma once
#include <SFML/Graphics.hpp>
#include <vector>
#include <string>
#include "Map.hpp"
#include "Player.hpp"

// Dimensions de la fenêtre
static const int WINDOW_W = Map::COLS * Map::CELL_SIZE;   // 900 px
static const int MAP_H    = Map::ROWS * Map::CELL_SIZE;   // 540 px
static const int PANEL_H  = 100;                          // Panneau UI en bas
static const int WINDOW_H = MAP_H + PANEL_H;              // 640 px

class Game {
public:
    Game();
    void run();  // Lance la boucle principale (événements → logique → affichage)

private:
    // --- Fenêtre & ressources ---
    sf::RenderWindow window;
    sf::Font         font;
    bool             fontLoaded;

    // --- État du jeu ---
    Map                 map;
    std::vector<Player> players;           // players[0] = J1, players[1] = J2
    int                 currentPlayerIndex;
    int                 turn;
    bool                gameOver;
    std::string         winnerName;
    std::string         message;

    // --- Interaction souris ---
    Camp* selectedCamp;  // nullptr = rien de sélectionné

    // --- Logique ---
    void handleClick(int mouseX, int mouseY);
    void collectIncome(int playerIndex);
    void endTurn();
    void checkVictory();

    // --- Affichage ---
    void render();
    void drawMap();
    void drawCamps();
    void drawUI();

    // --- Utilitaires ---
    bool      isEndTurnButton(int mx, int my) const;
    sf::Color getPlayerColor(int playerIndex) const;
    sf::Color getCellColor(CellType type)     const;
    void      drawText(const std::string& str, float x, float y,
                       unsigned int size, sf::Color color,
                       bool bold = false, bool centered = false);
};
