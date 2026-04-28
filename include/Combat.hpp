#pragma once

struct Camp;

// Résout un combat quand un joueur déplace ses unités vers un camp ennemi/neutre.
// - source : camp d'où viennent les attaquants (ses unités seront à 0 après)
// - target : camp attaqué
// Si l'attaquant gagne : il prend le camp avec ses unités survivantes.
// Si le défenseur gagne : les attaquants sont éliminés, le défenseur perd quelques unités.
void resolveCombat(Camp& source, Camp& target);
