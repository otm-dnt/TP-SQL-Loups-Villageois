TP SQL - Jeu "Les Loups et Villageois",
Ce projet est un TP noté sur SQL Server pour l'école EPSI, Campus de Paris/Courbevoie (B3).

Description,
Implémentation d'une base de données SQL Server pour un jeu multijoueur "Les Loups et Villageois". Le jeu consiste en un plateau 2D où:
Les loups doivent éliminer tous les villageois,
Les villageois doivent survivre jusqu'à la fin des tours,

Structure de la base de données,
La base de données contient les tables suivantes:
Game: Configuration de la partie (nombre de lignes, colonnes, etc.),
Player: Informations sur les joueurs,
Cell: Cellules du plateau de jeu,
Turn: Tours de jeu,
GamePlayer: Association entre joueurs et parties,
Move: Déplacements des joueurs,

Améliorations apportées,
Types de données appropriés: Utilisation de NVARCHAR pour les chaînes, contrôle des valeurs obligatoires (NOT NULL),
Contraintes de vérification (CHECK): Valeurs positives, déplacements valides (pas de diagonales),
Contraintes d'unicité (UNIQUE): Identifiants uniques, positions uniques sur le plateau,
Clés étrangères: Relations entre les tables avec CASCADE pour la suppression,
Triggers: Vérification des règles métier complexes (nombre max de joueurs, obstacles, éliminations),
Index: Optimisation des requêtes fréquentes,

Comment utiliser,
Exécuter wv_schema.sql pour créer les tables de base,
Exécuter wv_index.sql pour ajouter les contraintes et optimisations,
Utiliser les exemples dans wv_test.sql pour tester les fonctionnalités,

Auteur,
[Dounit] - EPSI B3