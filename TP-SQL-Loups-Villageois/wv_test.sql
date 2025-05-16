-- Script de test pour vérifier que les contraintes fonctionnent
-- Créer une nouvelle partie
INSERT INTO Game (name, nb_rows, nb_columns, max_wait_time, nb_turns, nb_obstacles, max_players)
VALUES ('Partie test', 10, 10, 30, 20, 10, 8);

-- Récupérer l'ID de la partie
DECLARE @game_id INT = SCOPE_IDENTITY();
PRINT 'Partie créée avec ID: ' + CAST(@game_id AS NVARCHAR);

-- Créer quelques cellules
INSERT INTO Cell (game_id, row_position, column_position, cell_type)
VALUES 
(@game_id, 0, 0, 'Empty'),
(@game_id, 0, 1, 'Empty'),
(@game_id, 0, 2, 'Obstacle'),
(@game_id, 1, 0, 'Empty'),
(@game_id, 1, 1, 'Empty'),
(@game_id, 1, 2, 'Empty');

PRINT 'Cellules créées';

-- Créer des joueurs
INSERT INTO Player (player_id)
VALUES ('joueur1'), ('joueur2');

PRINT 'Joueurs créés';

-- Récupérer les IDs des joueurs
DECLARE @player1_id INT, @player2_id INT;
SELECT @player1_id = id FROM Player WHERE player_id = 'joueur1';
SELECT @player2_id = id FROM Player WHERE player_id = 'joueur2';

-- Associer les joueurs à la partie
INSERT INTO GamePlayer (game_id, player_id, role, is_eliminated)
VALUES 
(@game_id, @player1_id, 'Loup', 0),
(@game_id, @player2_id, 'Villageois', 0);

PRINT 'Joueurs associés à la partie';

-- Créer un tour
INSERT INTO Turn (game_id, turn_number, start_time, is_completed)
VALUES (@game_id, 1, GETDATE(), 0);

DECLARE @turn_id INT = SCOPE_IDENTITY();
PRINT 'Tour créé avec ID: ' + CAST(@turn_id AS NVARCHAR);

-- Récupérer les IDs des cellules
DECLARE @cell1_id INT, @cell2_id INT;
SELECT @cell1_id = id FROM Cell WHERE game_id = @game_id AND row_position = 0 AND column_position = 0;
SELECT @cell2_id = id FROM Cell WHERE game_id = @game_id AND row_position = 0 AND column_position = 1;

-- Récupérer l'ID du GamePlayer pour le loup
DECLARE @gameplayer_id INT;
SELECT @gameplayer_id = id FROM GamePlayer WHERE game_id = @game_id AND player_id = @player1_id;

-- Faire un déplacement valide pour le loup
INSERT INTO Move (turn_id, game_player_id, source_cell_id, destination_cell_id, 
                 source_row, source_column, destination_row, destination_column)
VALUES (@turn_id, @gameplayer_id, @cell1_id, @cell2_id, 0, 0, 0, 1);

PRINT 'Déplacement enregistré';

-- Terminer le tour
UPDATE Turn SET is_completed = 1, end_time = GETDATE() WHERE id = @turn_id;

PRINT 'Tour terminé';

-- Test des contraintes - Ces requêtes devraient échouer

-- 1. Test de la contrainte sur les valeurs positives
BEGIN TRY
    INSERT INTO Game (name, nb_rows, nb_columns, max_wait_time, nb_turns, nb_obstacles, max_players)
    VALUES ('Test invalide', -1, 10, 30, 20, 10, 8);
    PRINT 'ERREUR: La contrainte sur les valeurs positives n''a pas fonctionné';
END TRY
BEGIN CATCH
    PRINT 'OK: La contrainte sur les valeurs positives fonctionne';
END CATCH

-- 2. Test de la contrainte sur l'unicité d'une cellule
BEGIN TRY
    INSERT INTO Cell (game_id, row_position, column_position, cell_type)
    VALUES (@game_id, 0, 0, 'Empty'); -- Cellule qui existe déjà
    PRINT 'ERREUR: La contrainte sur l''unicité des cellules n''a pas fonctionné';
END TRY
BEGIN CATCH
    PRINT 'OK: La contrainte sur l''unicité des cellules fonctionne';
END CATCH

-- 3. Test de la contrainte sur les déplacements (pas de diagonale)
BEGIN TRY
    INSERT INTO Move (turn_id, game_player_id, source_cell_id, destination_cell_id, 
                     source_row, source_column, destination_row, destination_column)
    VALUES (@turn_id, @gameplayer_id, @cell1_id, @cell2_id, 0, 0, 1, 1); -- Déplacement en diagonale
    PRINT 'ERREUR: La contrainte sur les déplacements diagonaux n''a pas fonctionné';
END TRY
BEGIN CATCH
    PRINT 'OK: La contrainte sur les déplacements diagonaux fonctionne';
END CATCH

-- 4. Test du trigger pour empêcher de se déplacer sur un obstacle
BEGIN TRY
    DECLARE @obstacle_id INT;
    SELECT @obstacle_id = id FROM Cell WHERE game_id = @game_id AND row_position = 0 AND column_position = 2;
    
    INSERT INTO Move (turn_id, game_player_id, source_cell_id, destination_cell_id, 
                     source_row, source_column, destination_row, destination_column)
    VALUES (@turn_id, @gameplayer_id, @cell2_id, @obstacle_id, 0, 1, 0, 2); -- Déplacement sur un obstacle
    PRINT 'ERREUR: Le trigger empêchant de se déplacer sur un obstacle n''a pas fonctionné';
END TRY
BEGIN CATCH
    PRINT 'OK: Le trigger empêchant de se déplacer sur un obstacle fonctionne';
END CATCH

PRINT 'Tous les tests sont terminés';