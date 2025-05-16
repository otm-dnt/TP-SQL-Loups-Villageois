-- wv_index.sql - Améliorations et contraintes pour la base de données du jeu "Les Loups"

-- 1. Modification des types et ajout de contraintes aux tables existantes

-- Table Game (Partie)
ALTER TABLE Game
    ALTER COLUMN name NVARCHAR(50) NOT NULL;

-- Contraintes pour les paramètres du jeu (valeurs positives)
ALTER TABLE Game
    ADD CONSTRAINT CK_Game_NbRows CHECK (nb_rows > 0),
    CONSTRAINT CK_Game_NbColumns CHECK (nb_columns > 0),
    CONSTRAINT CK_Game_MaxWaitTime CHECK (max_wait_time > 0),
    CONSTRAINT CK_Game_NbTurns CHECK (nb_turns > 0),
    CONSTRAINT CK_Game_NbObstacles CHECK (nb_obstacles >= 0),
    CONSTRAINT CK_Game_MaxPlayers CHECK (max_players > 0);

-- Table Player (Joueur)
ALTER TABLE Player
    ALTER COLUMN player_id NVARCHAR(50) NOT NULL;

-- Contrainte unicité de l'identifiant du joueur
ALTER TABLE Player
    ADD CONSTRAINT UQ_Player_PlayerId UNIQUE (player_id);

-- Table Cell (Cellule)
ALTER TABLE Cell
    ADD CONSTRAINT CK_Cell_RowColumn CHECK (row_position >= 0 AND column_position >= 0);

-- Contrainte unicité d'une cellule dans une partie
ALTER TABLE Cell
    ADD CONSTRAINT UQ_Cell_GameRowColumn UNIQUE (game_id, row_position, column_position);

-- Table Turn (Tour)
ALTER TABLE Turn
    ADD CONSTRAINT CK_Turn_Number CHECK (turn_number > 0);

-- Contrainte unicité d'un numéro de tour dans une partie
ALTER TABLE Turn
    ADD CONSTRAINT UQ_Turn_GameTurnNumber UNIQUE (game_id, turn_number);

-- Table GamePlayer (Association Partie-Joueur)
-- Contrainte unicité d'un joueur dans une partie
ALTER TABLE GamePlayer
    ADD CONSTRAINT UQ_GamePlayer_GamePlayer UNIQUE (game_id, player_id);

-- Contrainte sur le rôle du joueur (loup ou villageois)
ALTER TABLE GamePlayer
    ADD CONSTRAINT CK_GamePlayer_Role CHECK (role IN ('Loup', 'Villageois'));

-- Table Move (Déplacement)
-- Contrainte sur la validité du déplacement (lignes ou colonnes, pas de diagonale)
ALTER TABLE Move
    ADD CONSTRAINT CK_Move_ValidMove CHECK (
        (source_row = destination_row AND source_column != destination_column) OR
        (source_row != destination_row AND source_column = destination_column)
    );

-- 2. Ajout des contraintes de clés étrangères

-- Cell référence Game
ALTER TABLE Cell
    ADD CONSTRAINT FK_Cell_Game FOREIGN KEY (game_id)
    REFERENCES Game (id)
    ON DELETE CASCADE;

-- Turn référence Game
ALTER TABLE Turn
    ADD CONSTRAINT FK_Turn_Game FOREIGN KEY (game_id)
    REFERENCES Game (id)
    ON DELETE CASCADE;

-- GamePlayer référence Game et Player
ALTER TABLE GamePlayer
    ADD CONSTRAINT FK_GamePlayer_Game FOREIGN KEY (game_id)
    REFERENCES Game (id)
    ON DELETE CASCADE;

ALTER TABLE GamePlayer
    ADD CONSTRAINT FK_GamePlayer_Player FOREIGN KEY (player_id)
    REFERENCES Player (id)
    ON DELETE CASCADE;

-- Move référence Turn, GamePlayer et Cell (source et destination)
ALTER TABLE Move
    ADD CONSTRAINT FK_Move_Turn FOREIGN KEY (turn_id)
    REFERENCES Turn (id)
    ON DELETE CASCADE;

ALTER TABLE Move
    ADD CONSTRAINT FK_Move_GamePlayer FOREIGN KEY (game_player_id)
    REFERENCES GamePlayer (id)
    ON DELETE CASCADE;

ALTER TABLE Move
    ADD CONSTRAINT FK_Move_SourceCell FOREIGN KEY (source_cell_id)
    REFERENCES Cell (id);

ALTER TABLE Move
    ADD CONSTRAINT FK_Move_DestinationCell FOREIGN KEY (destination_cell_id)
    REFERENCES Cell (id);

-- 3. Ajout des règles de validation métier (triggers)

-- Trigger pour vérifier que le nombre de joueurs ne dépasse pas le maximum autorisé
CREATE OR ALTER TRIGGER TR_GamePlayer_MaxPlayers
ON GamePlayer
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT g.id, COUNT(gp.id) as player_count
        FROM Game g
        JOIN GamePlayer gp ON g.id = gp.game_id
        GROUP BY g.id
        HAVING COUNT(gp.id) > g.max_players
    )
    BEGIN
        ROLLBACK;
        THROW 50001, 'Le nombre maximum de joueurs pour cette partie est atteint.', 1;
    END
END;

-- Trigger pour vérifier qu'un obstacle n'est pas déplacé
CREATE OR ALTER TRIGGER TR_Move_NoObstacleMove
ON Move
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT m.id
        FROM inserted m
        JOIN Cell c ON m.source_cell_id = c.id
        WHERE c.cell_type = 'Obstacle'
    )
    BEGIN
        ROLLBACK;
        THROW 50002, 'Un obstacle ne peut pas être déplacé.', 1;
    END
END;

-- Trigger pour vérifier qu'un joueur ne se déplace pas sur un obstacle
CREATE OR ALTER TRIGGER TR_Move_NoMoveToObstacle
ON Move
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT m.id
        FROM inserted m
        JOIN Cell c ON m.destination_cell_id = c.id
        WHERE c.cell_type = 'Obstacle'
    )
    BEGIN
        ROLLBACK;
        THROW 50003, 'Un joueur ne peut pas se déplacer sur un obstacle.', 1;
    END
END;

-- Trigger pour résoudre les éliminations de villageois à la fin d'un tour
CREATE OR ALTER TRIGGER TR_Turn_EliminateVillagers
ON Turn
AFTER UPDATE
AS
BEGIN
    -- Si le tour est terminé
    IF EXISTS (SELECT 1 FROM inserted WHERE is_completed = 1)
    BEGIN
        -- Marquer les villageois comme éliminés s'ils sont sur la même case qu'un loup
        UPDATE gp
        SET is_eliminated = 1
        FROM GamePlayer gp
        JOIN Move mv_villager ON gp.id = mv_villager.game_player_id
        JOIN Turn t ON mv_villager.turn_id = t.id
        WHERE 
            gp.role = 'Villageois'
            AND gp.is_eliminated = 0
            AND EXISTS (
                SELECT 1
                FROM Move mv_wolf
                JOIN GamePlayer gp_wolf ON mv_wolf.game_player_id = gp_wolf.id
                WHERE 
                    gp_wolf.role = 'Loup'
                    AND mv_wolf.turn_id = mv_villager.turn_id
                    AND mv_wolf.destination_cell_id = mv_villager.destination_cell_id
            );
    END
END;

-- 4. Ajout d'index pour optimiser les performances

-- Index sur les positions des cellules pour accélérer les recherches spatiales
CREATE INDEX IX_Cell_Position ON Cell (game_id, row_position, column_position);

-- Index sur les tours pour accélérer la recherche par partie et numéro de tour
CREATE INDEX IX_Turn_GameTurnNumber ON Turn (game_id, turn_number);

-- Index pour accélérer la recherche des mouvements par tour
CREATE INDEX IX_Move_Turn ON Move (turn_id);

-- Index pour accélérer la recherche des joueurs dans une partie
CREATE INDEX IX_GamePlayer_GamePlayer ON GamePlayer (game_id, player_id);