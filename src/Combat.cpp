#include "Combat.hpp"
#include "Camp.hpp"
#include <cstdlib>
#include <algorithm>

void resolveCombat(Camp& source, Camp& target) {
    int attaquants  = source.units;
    int defenseurs  = target.units;

    // Calcul de force : unités × 10 + tirage aléatoire pour l'imprévu
    // L'attaquant a un léger avantage (×4 aléatoire vs ×3 pour le défenseur)
    int forceAtt = attaquants * 10 + (rand() % (attaquants * 4 + 1));
    int forceDef = defenseurs * 10 + (rand() % (defenseurs * 3 + 1));

    if (forceAtt >= forceDef) {
        // --- Victoire de l'attaquant ---
        // Il perd la moitié des défenseurs en pertes, mais garde au moins 1 unité
        int pertes      = std::max(1, defenseurs / 2);
        int survivants  = std::max(1, attaquants - pertes);

        target.ownerIndex = source.ownerIndex;  // Changement de propriétaire
        target.units      = survivants;          // Les survivants occupent le camp
    } else {
        // --- Victoire du défenseur ---
        // L'attaque échoue : tous les attaquants meurent
        // Le défenseur perd quand même quelques unités
        int pertesDefenseur = std::max(0, attaquants / 2 - 1);
        target.units = std::max(1, defenseurs - pertesDefenseur);
    }

    // Dans les deux cas, le camp source perd toutes ses unités
    // (elles ont avancé ou ont été détruites)
    source.units = 0;
}
