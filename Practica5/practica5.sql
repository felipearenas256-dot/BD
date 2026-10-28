-- ---------------------------------------------------------------------
-- 0. ESQUEMA BASE (si ya tienes la BD de las Prácticas 1-4, adapta los
--    nombres de tablas/columnas y omite esta sección)
-- ---------------------------------------------------------------------
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS universidad_umb;
CREATE DATABASE universidad_umb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE universidad_umb;

CREATE TABLE Estudiante (
    IdEstudiante      INT AUTO_INCREMENT PRIMARY KEY,
    Nombre            VARCHAR(50)  NOT NULL,
    Apellido          VARCHAR(50)  NOT NULL,
    FechaNacimiento   DATE         NOT NULL,
    Email             VARCHAR(100) UNIQUE,
    Promedio          DECIMAL(3,2) NULL,
    EstadoAcademico   VARCHAR(15)  NOT NULL DEFAULT 'SIN NOTAS'
);

CREATE TABLE Curso (
    IdCurso   INT AUTO_INCREMENT PRIMARY KEY,
    Nombre    VARCHAR(80) NOT NULL,
    Creditos  TINYINT     NOT NULL
);

CREATE TABLE Matricula (
    IdMatricula      INT AUTO_INCREMENT PRIMARY KEY,
    IdEstudiante     INT          NOT NULL,
    IdCurso          INT          NOT NULL,
    FechaMatricula   DATE         NOT NULL,
    NotaFinal        DECIMAL(2,1) NULL,
    Estado           VARCHAR(12)  NOT NULL DEFAULT 'EN CURSO',
    CONSTRAINT uq_est_curso UNIQUE (IdEstudiante, IdCurso),
    CONSTRAINT fk_mat_est   FOREIGN KEY (IdEstudiante) REFERENCES Estudiante(IdEstudiante),
    CONSTRAINT fk_mat_curso FOREIGN KEY (IdCurso)      REFERENCES Curso(IdCurso)
);

-- Tabla de auditoría (usada por el trigger AFTER INSERT de la Actividad 5)
CREATE TABLE Auditoria_Matricula (
    IdAuditoria    INT AUTO_INCREMENT PRIMARY KEY,
    IdMatricula    INT          NOT NULL,
    IdEstudiante   INT          NOT NULL,
    IdCurso        INT          NOT NULL,
    Accion         VARCHAR(10)  NOT NULL,
    Usuario        VARCHAR(100) NOT NULL,
    FechaHora      DATETIME     NOT NULL
);

-- Datos de prueba
INSERT INTO Estudiante (Nombre, Apellido, FechaNacimiento, Email) VALUES
 ('Laura',   'Gómez',    '2003-05-14', 'laura.gomez@umb.edu.co'),
 ('Andrés',  'Rodríguez','2002-11-02', 'andres.rodriguez@umb.edu.co'),
 ('Camila',  'Torres',   '2004-01-23', 'camila.torres@umb.edu.co'),
 ('Julián',  'Martínez', '2001-08-30', 'julian.martinez@umb.edu.co'),
 ('Valentina','Ruiz',    '2005-03-09', 'valentina.ruiz@umb.edu.co');

INSERT INTO Curso (Nombre, Creditos) VALUES
 ('Teoría de Bases de Datos', 3),
 ('Programación Orientada a Objetos', 3),
 ('Estructuras de Datos', 4),
 ('Ingeniería de Software', 3);

INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES
 (1, 1, '2026-07-28', 4.8), (1, 2, '2026-07-28', 4.4), (1, 3, '2026-07-28', 4.6),
 (2, 1, '2026-07-28', 4.2), (2, 2, '2026-07-28', 3.9), (2, 3, '2026-07-28', 4.1),
 (3, 1, '2026-07-28', 3.2), (3, 2, '2026-07-28', 3.5), (3, 3, '2026-07-28', 2.9),
 (4, 1, '2026-07-28', 2.1), (4, 2, '2026-07-28', 2.8), (4, 3, '2026-07-28', 3.0),
 (5, 1, '2026-07-28', NULL);

-- =====================================================================
-- ACTIVIDAD 1 – PRIMER PROCEDIMIENTO ALMACENADO
-- Registra una matrícula verificando que existan estudiante y curso.
-- Devuelve un mensaje de éxito o error en el parámetro OUT p_mensaje.
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_registrar_matricula;
DELIMITER //
CREATE PROCEDURE sp_registrar_matricula(
    IN  p_id_estudiante INT,
    IN  p_id_curso      INT,
    OUT p_mensaje       VARCHAR(150)
)
BEGIN
    -- Captura cualquier error SQL no previsto y deshace la transacción
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_mensaje = 'ERROR: no se pudo registrar la matrícula (error SQL).';
    END;

    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE IdEstudiante = p_id_estudiante) THEN
        SET p_mensaje = CONCAT('ERROR: el estudiante ', p_id_estudiante, ' no existe.');
    ELSEIF NOT EXISTS (SELECT 1 FROM Curso WHERE IdCurso = p_id_curso) THEN
        SET p_mensaje = CONCAT('ERROR: el curso ', p_id_curso, ' no existe.');
    ELSEIF EXISTS (SELECT 1 FROM Matricula
                   WHERE IdEstudiante = p_id_estudiante AND IdCurso = p_id_curso) THEN
        SET p_mensaje = 'ERROR: el estudiante ya está matriculado en ese curso.';
    ELSE
        START TRANSACTION;
        INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula)
        VALUES (p_id_estudiante, p_id_curso, CURDATE());
        COMMIT;
        SET p_mensaje = CONCAT('OK: matrícula ', LAST_INSERT_ID(), ' registrada el ', CURDATE(), '.');
    END IF;
END //
DELIMITER ;

-- Pruebas Actividad 1
CALL sp_registrar_matricula(5, 2, @msg);   SELECT @msg AS caso_valido;
CALL sp_registrar_matricula(99, 1, @msg);  SELECT @msg AS estudiante_inexistente;
CALL sp_registrar_matricula(1, 99, @msg);  SELECT @msg AS curso_inexistente;
CALL sp_registrar_matricula(1, 1, @msg);   SELECT @msg AS matricula_duplicada;

-- =====================================================================
-- ACTIVIDAD 2 – SP CON LÓGICA DE NEGOCIO COMPLEJA
-- Calcula el promedio de un estudiante, lo clasifica y actualiza su estado.
-- Excelente (>=4.5) | Bueno (>=4.0) | Aprobado (>=3.0) | Reprobado (<3.0)
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_clasificar_estudiante;
DELIMITER //
CREATE PROCEDURE sp_clasificar_estudiante(
    IN  p_id_estudiante INT,
    OUT p_promedio      DECIMAL(3,2),
    OUT p_clasificacion VARCHAR(15)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Estudiante WHERE IdEstudiante = p_id_estudiante) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El estudiante no existe.';
    END IF;

    -- Solo se promedian materias con nota registrada
    SELECT ROUND(AVG(NotaFinal), 2) INTO p_promedio
    FROM Matricula
    WHERE IdEstudiante = p_id_estudiante AND NotaFinal IS NOT NULL;

    SET p_clasificacion = CASE
        WHEN p_promedio IS NULL THEN 'SIN NOTAS'
        WHEN p_promedio >= 4.5  THEN 'EXCELENTE'
        WHEN p_promedio >= 4.0  THEN 'BUENO'
        WHEN p_promedio >= 3.0  THEN 'APROBADO'
        ELSE 'REPROBADO'
    END;

    UPDATE Estudiante
    SET Promedio = p_promedio, EstadoAcademico = p_clasificacion
    WHERE IdEstudiante = p_id_estudiante;
END //
DELIMITER ;

-- Pruebas Actividad 2 (un caso por categoría)
CALL sp_clasificar_estudiante(1, @prom, @clas); SELECT 1 AS id, @prom AS promedio, @clas AS clasificacion;
CALL sp_clasificar_estudiante(2, @prom, @clas); SELECT 2 AS id, @prom AS promedio, @clas AS clasificacion;
CALL sp_clasificar_estudiante(3, @prom, @clas); SELECT 3 AS id, @prom AS promedio, @clas AS clasificacion;
CALL sp_clasificar_estudiante(4, @prom, @clas); SELECT 4 AS id, @prom AS promedio, @clas AS clasificacion;
CALL sp_clasificar_estudiante(5, @prom, @clas); SELECT 5 AS id, @prom AS promedio, @clas AS clasificacion;
SELECT IdEstudiante, Nombre, Apellido, Promedio, EstadoAcademico FROM Estudiante;

-- =====================================================================
-- ACTIVIDAD 3 – FUNCIONES DEFINIDAS POR EL USUARIO (UDF)
-- =====================================================================
DROP FUNCTION IF EXISTS fn_calcular_edad;
DROP FUNCTION IF EXISTS fn_formatear_nombre;
DELIMITER //
-- Edad en años cumplidos a partir de la fecha de nacimiento
CREATE FUNCTION fn_calcular_edad(p_fecha_nac DATE)
RETURNS INT
NOT DETERMINISTIC      -- depende de CURDATE(), cambia con el tiempo
NO SQL
BEGIN
    IF p_fecha_nac IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN TIMESTAMPDIFF(YEAR, p_fecha_nac, CURDATE());
END //

-- Devuelve "APELLIDO, NOMBRE" en mayúsculas y sin espacios sobrantes
CREATE FUNCTION fn_formatear_nombre(p_nombre VARCHAR(50), p_apellido VARCHAR(50))
RETURNS VARCHAR(105)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT(UPPER(TRIM(p_apellido)), ', ', UPPER(TRIM(p_nombre)));
END //
DELIMITER ;

-- Uso de las funciones dentro de un SELECT
SELECT IdEstudiante,
       fn_formatear_nombre(Nombre, Apellido) AS NombreCompleto,
       FechaNacimiento,
       fn_calcular_edad(FechaNacimiento)     AS Edad
FROM Estudiante
ORDER BY NombreCompleto;

-- =====================================================================
-- ACTIVIDAD 4 – PROCEDIMIENTO CON CURSOR
-- Recorre las matrículas de un curso y actualiza el estado según la nota:
-- NotaFinal >= 3.0 -> APROBADO | < 3.0 -> REPROBADO | NULL -> EN CURSO
-- =====================================================================
DROP PROCEDURE IF EXISTS sp_actualizar_estados_curso;
DELIMITER //
CREATE PROCEDURE sp_actualizar_estados_curso(
    IN  p_id_curso     INT,
    OUT p_procesados   INT
)
BEGIN
    DECLARE v_fin          BOOLEAN DEFAULT FALSE;
    DECLARE v_id_matricula INT;
    DECLARE v_nota         DECIMAL(2,1);
    DECLARE v_estado       VARCHAR(12);

    -- 1) Declarar el cursor con la consulta a recorrer
    DECLARE cur_matriculas CURSOR FOR
        SELECT IdMatricula, NotaFinal
        FROM Matricula
        WHERE IdCurso = p_id_curso;

    -- 2) Handler que marca el fin del recorrido
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_fin = TRUE;

    SET p_procesados = 0;
    OPEN cur_matriculas;

    recorrido: LOOP
        FETCH cur_matriculas INTO v_id_matricula, v_nota;
        IF v_fin THEN
            LEAVE recorrido;
        END IF;

        IF v_nota IS NULL THEN
            SET v_estado = 'EN CURSO';
        ELSEIF v_nota >= 3.0 THEN
            SET v_estado = 'APROBADO';
        ELSE
            SET v_estado = 'REPROBADO';
        END IF;

        UPDATE Matricula SET Estado = v_estado WHERE IdMatricula = v_id_matricula;
        SET p_procesados = p_procesados + 1;
    END LOOP recorrido;

    CLOSE cur_matriculas;
END //
DELIMITER ;

-- ANTES
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, m.NotaFinal, m.Estado
FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante
WHERE m.IdCurso = 1 ORDER BY m.IdMatricula;

CALL sp_actualizar_estados_curso(1, @n);
SELECT @n AS matriculas_procesadas;

-- DESPUÉS
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, m.NotaFinal, m.Estado
FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante
WHERE m.IdCurso = 1 ORDER BY m.IdMatricula;

-- =====================================================================
-- ACTIVIDAD 5 – INTEGRACIÓN CON TRIGGERS
-- =====================================================================
DROP TRIGGER IF EXISTS trg_matricula_valida_nota;
DROP TRIGGER IF EXISTS trg_matricula_valida_nota_upd;
DROP TRIGGER IF EXISTS trg_matricula_auditoria;
DELIMITER //
-- BEFORE INSERT: rechaza notas fuera del rango 0.0 – 5.0
CREATE TRIGGER trg_matricula_valida_nota
BEFORE INSERT ON Matricula
FOR EACH ROW
BEGIN
    IF NEW.NotaFinal IS NOT NULL AND (NEW.NotaFinal < 0 OR NEW.NotaFinal > 5.0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La nota debe estar entre 0.0 y 5.0';
    END IF;
END //

-- (Complemento) BEFORE UPDATE: misma validación al modificar una nota
CREATE TRIGGER trg_matricula_valida_nota_upd
BEFORE UPDATE ON Matricula
FOR EACH ROW
BEGIN
    IF NEW.NotaFinal IS NOT NULL AND (NEW.NotaFinal < 0 OR NEW.NotaFinal > 5.0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La nota debe estar entre 0.0 y 5.0';
    END IF;
END //

-- AFTER INSERT: deja rastro de cada matrícula nueva en la auditoría
CREATE TRIGGER trg_matricula_auditoria
AFTER INSERT ON Matricula
FOR EACH ROW
BEGIN
    INSERT INTO Auditoria_Matricula (IdMatricula, IdEstudiante, IdCurso, Accion, Usuario, FechaHora)
    VALUES (NEW.IdMatricula, NEW.IdEstudiante, NEW.IdCurso, 'INSERT', CURRENT_USER(), NOW());
END //
DELIMITER ;

-- Pruebas Actividad 5
-- a) Nota válida -> se inserta y queda auditada
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal)
VALUES (5, 3, CURDATE(), 4.0);

-- b) Notas inválidas -> el trigger las rechaza
--    (ERROR 1644 (45000): La nota debe estar entre 0.0 y 5.0)
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal)
VALUES (3, 4, CURDATE(), 5.5);
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal)
VALUES (2, 4, CURDATE(), -1.0);
-- Variante UPDATE (trigger BEFORE UPDATE)
UPDATE Matricula SET NotaFinal = 7.0 WHERE IdMatricula = 1;

-- c) Matrícula registrada vía el SP de la Actividad 1 también queda auditada
CALL sp_registrar_matricula(4, 4, @msg); SELECT @msg AS resultado_sp;

SELECT * FROM Auditoria_Matricula;
