-- wv_schema.sql - Schéma initial pour le jeu Les Loups

-- Suppression des tables si elles existent déjà
IF OBJECT_ID('Move', 'U') IS NOT NULL DROP TABLE Move;
IF OBJECT_ID('GamePlayer', 'U') IS NOT NULL DROP TABLE GamePlayer;
IF OBJECT_ID('Turn', 'U') IS NOT NULL DROP TABLE Turn;
IF OBJECT_ID('Cell', 'U') IS NOT NULL DROP TABLE Cell;
IF OBJECT_ID('Player', 'U') IS NOT NULL DROP TABLE Player;
IF OBJECT_ID('Game', 'U') IS NOT NULL DROP TABLE Game;

-- Création de la table Game (Partie)
CREATE TABLE Game (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100),
    nb_rows INT,
    nb_columns INT,
    max_wait_time INT,
    nb_turns INT,
    nb_obstacles INT,
    max_players INT
);

-- Création de la table Player (Joueur)
CREATE TABLE Player (
    id INT IDENTITY(1,1) PRIMARY KEY,
    player_id VARCHAR(100)
);

-- Création de la table Cell (Cellule)
CREATE TABLE Cell (
    id INT IDENTITY(1,1) PRIMARY KEY,
    game_id INT,
    row_position INT,
    column_position INT,
    cell_type VARCHAR(10) -- 'Empty', 'Obstacle', 'Loup', 'Villageois'
);

-- Création de la table Turn (Tour)
CREATE TABLE Turn (
    id INT IDENTITY(1,1) PRIMARY KEY,
    game_id INT,
    turn_number INT,
    start_time DATETIME,
    end_time DATETIME,
    is_completed BIT DEFAULT 0
);

-- Création de la table GamePlayer (Association Partie-Joueur)
CREATE TABLE GamePlayer (
    id INT IDENTITY(1,1) PRIMARY KEY,
    game_id INT,
    player_id INT,
    role VARCHAR(10), -- 'Loup' ou 'Villageois'
    is_eliminated BIT DEFAULT 0
);

-- Création de la table Move (Déplacement)
CREATE TABLE Move (
    id INT IDENTITY(1,1) PRIMARY KEY,
    turn_id INT,
    game_player_id INT,
    source_cell_id INT,
    destination_cell_id INT,
    source_row INT,
    source_column INT,
    destination_row INT,
    destination_column INT
);