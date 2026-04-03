#include "Game.hpp"
#include "Combat.hpp"
#include <cstdlib>
#include <ctime>
#include <string>

// Position et taille du bouton "Fin de tour"
static const float BTN_X = 750.f;
static const float BTN_Y = static_cast<float>(MAP_H) + 30.f;
static const float BTN_W = 140.f;
static const float BTN_H = 40.f;

// ─────────────────────────────────────────
// Constructeur
// ─────────────────────────────────────────
Game::Game()
    : window(sf::VideoMode({static_cast<unsigned>(WINDOW_W),
                             static_cast<unsigned>(WINDOW_H)}),
             "SupKontQuest - Phase 1",
             sf::State::Windowed),
      fontLoaded(false),
      currentPlayerIndex(0),
      turn(1),
      gameOver(false),
      selectedCamp(nullptr),
      message("Joueur 1 - Selectionnez un de vos camps")
{
    srand(static_cast<unsigned>(time(nullptr)));
    window.setFramerateLimit(60);

    // Charger la police système Windows (SFML 3 : openFromFile)
    fontLoaded = font.openFromFile("C:/Windows/Fonts/arial.ttf");
    if (!fontLoaded)
        fontLoaded = font.openFromFile("C:/Windows/Fonts/calibri.ttf");

    // Initialiser les joueurs
    players.push_back({"Joueur 1", 0});
    players.push_back({"Joueur 2", 0});

    // Le Joueur 1 reçoit son revenu de départ
    collectIncome(0);
}

// ─────────────────────────────────────────
// Boucle principale
// ─────────────────────────────────────────
void Game::run() {
    // SFML 3 : pollEvent retourne std::optional<sf::Event>
    while (window.isOpen()) {
        while (const std::optional<sf::Event> event = window.pollEvent()) {

            // Fermer la fenêtre
            if (event->is<sf::Event::Closed>())
                window.close();

            if (!gameOver) {
                // Clic gauche
                if (const auto* e = event->getIf<sf::Event::MouseButtonPressed>()) {
                    if (e->button == sf::Mouse::Button::Left)
                        handleClick(e->position.x, e->position.y);
                }

                // Touche P → produire une unité (10 or)
                if (const auto* e = event->getIf<sf::Event::KeyPressed>()) {
                    if (e->code == sf::Keyboard::Key::P &&
                        selectedCamp != nullptr &&
                        selectedCamp->ownerIndex == currentPlayerIndex)
                    {
                        if (players[currentPlayerIndex].gold >= 10) {
                            players[currentPlayerIndex].gold -= 10;
                            selectedCamp->units++;
                            message = "Unite produite a " + selectedCamp->name +
                                      " (" + std::to_string(selectedCamp->units) + " unites)";
                        } else {
                            message = "Pas assez d'or ! Il faut 10 or.";
                        }
                    }
                }
            }
        }

        render();
    }
}

// ─────────────────────────────────────────
// Gestion du clic
// ─────────────────────────────────────────
void Game::handleClick(int mx, int my) {
    // Bouton "Fin de tour"
    if (isEndTurnButton(mx, my)) {
        endTurn();
        return;
    }

    // Ignorer les clics hors de la carte
    if (my >= MAP_H) return;

    int gridX = mx / Map::CELL_SIZE;
    int gridY = my / Map::CELL_SIZE;
    Camp* clicked = map.getCampAt(gridX, gridY);

    // ── Aucun camp sélectionné ──
    if (selectedCamp == nullptr) {
        if (clicked != nullptr && clicked->ownerIndex == currentPlayerIndex) {
            if (clicked->units > 0) {
                selectedCamp = clicked;
                message = clicked->name + " selectionne (" +
                          std::to_string(clicked->units) +
                          " unites) | Clic = deplacer | [P] = produire (10 or)";
            } else {
                message = "Ce camp n'a pas d'unites !";
            }
        }
        return;
    }

    // ── Un camp est déjà sélectionné ──
    if (clicked == nullptr || clicked == selectedCamp) {
        selectedCamp = nullptr;
        message = players[currentPlayerIndex].name + " - Selectionnez un camp";
        return;
    }

    if (clicked->ownerIndex == currentPlayerIndex) {
        // Camp allié : fusionner
        clicked->units += selectedCamp->units;
        selectedCamp->units = 0;
        message = "Unites fusionnees vers " + clicked->name +
                  " (" + std::to_string(clicked->units) + " unites)";

    } else {
        // Camp ennemi ou neutre : combat
        std::string nomSrc  = selectedCamp->name;
        std::string nomTgt  = clicked->name;
        int attBefore       = selectedCamp->units;
        int defBefore       = clicked->units;

        resolveCombat(*selectedCamp, *clicked);

        if (clicked->ownerIndex == currentPlayerIndex)
            message = "Victoire ! " + nomSrc + " prend " + nomTgt +
                      " (" + std::to_string(attBefore) + " vs " +
                      std::to_string(defBefore) + ")";
        else
            message = "Defaite ! Attaque repoussee sur " + nomTgt +
                      " (" + std::to_string(attBefore) + " vs " +
                      std::to_string(defBefore) + ")";
        checkVictory();
    }

    selectedCamp = nullptr;
}

// ─────────────────────────────────────────
// Logique
// ─────────────────────────────────────────
void Game::collectIncome(int playerIndex) {
    for (Camp& camp : map.getCamps())
        if (camp.ownerIndex == playerIndex)
            players[playerIndex].gold += camp.income;
}

void Game::endTurn() {
    selectedCamp       = nullptr;
    currentPlayerIndex = 1 - currentPlayerIndex;
    collectIncome(currentPlayerIndex);
    if (currentPlayerIndex == 0) turn++;
    message = players[currentPlayerIndex].name + " - Selectionnez un camp";
}

void Game::checkVictory() {
    int counts[2] = {0, 0};
    for (Camp& camp : map.getCamps()) {
        if (camp.ownerIndex == 0) counts[0]++;
        if (camp.ownerIndex == 1) counts[1]++;
    }
    int total = static_cast<int>(map.getCamps().size());
    for (int i = 0; i < 2; i++) {
        if (counts[i] == total) {
            gameOver   = true;
            winnerName = players[i].name;
            message    = players[i].name + " GAGNE LA PARTIE !";
        }
    }
}

// ─────────────────────────────────────────
// Affichage
// ─────────────────────────────────────────
void Game::render() {
    window.clear(sf::Color(20, 20, 20));
    drawMap();
    drawCamps();
    drawUI();
    window.display();
}

void Game::drawMap() {
    const int S = Map::CELL_SIZE;
    for (int x = 0; x < Map::COLS; x++) {
        for (int y = 0; y < Map::ROWS; y++) {
            sf::RectangleShape cell(sf::Vector2f(S - 2.f, S - 2.f));
            cell.setPosition(sf::Vector2f(x * S + 1.f, y * S + 1.f));
            cell.setFillColor(getCellColor(map.getCell(x, y).type));
            window.draw(cell);
        }
    }
}

void Game::drawCamps() {
    const float S      = static_cast<float>(Map::CELL_SIZE);
    const float RADIUS = 28.f;

    for (Camp& camp : map.getCamps()) {
        float cx = camp.x * S + S / 2.f;
        float cy = camp.y * S + S / 2.f;

        // Cercle coloré selon le propriétaire
        sf::CircleShape circle(RADIUS);
        circle.setOrigin(sf::Vector2f(RADIUS, RADIUS));
        circle.setPosition(sf::Vector2f(cx, cy));
        circle.setFillColor(getPlayerColor(camp.ownerIndex));

        if (&camp == selectedCamp) {
            circle.setOutlineThickness(4.f);
            circle.setOutlineColor(sf::Color::Yellow);
        } else {
            circle.setOutlineThickness(2.f);
            circle.setOutlineColor(sf::Color::Black);
        }
        window.draw(circle);

        // Nombre d'unités
        drawText(std::to_string(camp.units), cx, cy - 7.f,
                 22, sf::Color::White, true, true);

        // Nom du camp
        drawText(camp.name, cx, cy + 16.f,
                 11, sf::Color::White, false, true);
    }
}

void Game::drawUI() {
    float py = static_cast<float>(MAP_H);

    // Fond du panneau
    sf::RectangleShape panel(sf::Vector2f(WINDOW_W, PANEL_H));
    panel.setPosition(sf::Vector2f(0.f, py));
    panel.setFillColor(sf::Color(35, 35, 35));
    window.draw(panel);

    // Ligne de séparation
    sf::RectangleShape line(sf::Vector2f(WINDOW_W, 2.f));
    line.setPosition(sf::Vector2f(0.f, py));
    line.setFillColor(sf::Color(80, 80, 80));
    window.draw(line);

    Player& cur = players[currentPlayerIndex];

    drawText(cur.name,
             12.f, py + 8.f, 20,
             getPlayerColor(currentPlayerIndex), true);

    drawText("Or : " + std::to_string(cur.gold),
             12.f, py + 35.f, 17,
             sf::Color(255, 210, 0));

    drawText("Tour " + std::to_string(turn),
             12.f, py + 62.f, 15,
             sf::Color(180, 180, 180));

    drawText(message, 200.f, py + 42.f, 14, sf::Color(220, 220, 220));

    // Bouton "Fin de tour"
    sf::RectangleShape btn(sf::Vector2f(BTN_W, BTN_H));
    btn.setPosition(sf::Vector2f(BTN_X, BTN_Y));
    btn.setFillColor(sf::Color(60, 90, 170));
    btn.setOutlineThickness(2.f);
    btn.setOutlineColor(sf::Color(100, 140, 220));
    window.draw(btn);
    drawText("Fin de tour",
             BTN_X + BTN_W / 2.f, BTN_Y + BTN_H / 2.f - 8.f,
             16, sf::Color::White, false, true);

    // Écran de fin de partie
    if (gameOver) {
        sf::RectangleShape overlay(
            sf::Vector2f(static_cast<float>(WINDOW_W),
                         static_cast<float>(WINDOW_H)));
        overlay.setFillColor(sf::Color(0, 0, 0, 160));
        window.draw(overlay);

        drawText(winnerName + " GAGNE !",
                 WINDOW_W / 2.f, WINDOW_H / 2.f - 20.f,
                 42, sf::Color::Yellow, true, true);
        drawText("Fermez la fenetre pour quitter.",
                 WINDOW_W / 2.f, WINDOW_H / 2.f + 40.f,
                 18, sf::Color::White, false, true);
    }
}

// ─────────────────────────────────────────
// Utilitaires
// ─────────────────────────────────────────
bool Game::isEndTurnButton(int mx, int my) const {
    return (mx >= BTN_X && mx <= BTN_X + BTN_W &&
            my >= BTN_Y && my <= BTN_Y + BTN_H);
}

sf::Color Game::getPlayerColor(int playerIndex) const {
    if (playerIndex == 0) return sf::Color(60, 120, 200);
    if (playerIndex == 1) return sf::Color(200, 55, 55);
    return sf::Color(130, 130, 130);
}

sf::Color Game::getCellColor(CellType type) const {
    switch (type) {
        case CellType::PLAIN:  return sf::Color(150, 200, 110);
        case CellType::FOREST: return sf::Color(45, 110, 45);
        case CellType::WATER:  return sf::Color(70, 140, 210);
    }
    return sf::Color::White;
}

void Game::drawText(const std::string& str, float x, float y,
                    unsigned int size, sf::Color color,
                    bool bold, bool centered)
{
    if (!fontLoaded) return;

    // SFML 3 : sf::Text(font, string, size)
    sf::Text text(font, str, size);
    text.setFillColor(color);
    if (bold) text.setStyle(sf::Text::Bold);

    if (centered) {
        // SFML 3 : FloatRect a position et size (plus de .left / .width)
        sf::FloatRect b = text.getLocalBounds();
        text.setOrigin(sf::Vector2f(b.position.x + b.size.x / 2.f,
                                    b.position.y + b.size.y / 2.f));
    }
    text.setPosition(sf::Vector2f(x, y));
    window.draw(text);
}
