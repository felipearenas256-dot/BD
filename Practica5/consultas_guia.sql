-- PRACTICA 5 - Consultas por punto de la guia
-- Antes: 'Reiniciar base' en el panel, o:  bash ejecutar_p5.sh
-- Terminal: mysql -h 127.0.0.1 -u root -p'RootLab_P4_2026!' --default-character-set=utf8mb4 --force -t universidad_umb < consultas_guia.sql
USE universidad_umb;
-- ===== ACTIVIDAD 1 =====
CALL sp_registrar_matricula(3, 4, @msg); SELECT @msg AS caso_valido;
CALL sp_registrar_matricula(99, 1, @msg); SELECT @msg AS estudiante_inexistente;
CALL sp_registrar_matricula(1, 99, @msg); SELECT @msg AS curso_inexistente;
CALL sp_registrar_matricula(3, 4, @msg); SELECT @msg AS duplicada;
SELECT * FROM Matricula WHERE IdEstudiante = 3 ORDER BY IdMatricula;
-- ===== ACTIVIDAD 2 =====
CALL sp_clasificar_estudiante(1, @p, @c); SELECT 1 AS id, @p AS promedio, @c AS clasificacion;
CALL sp_clasificar_estudiante(2, @p, @c); SELECT 2 AS id, @p AS promedio, @c AS clasificacion;
CALL sp_clasificar_estudiante(3, @p, @c); SELECT 3 AS id, @p AS promedio, @c AS clasificacion;
CALL sp_clasificar_estudiante(4, @p, @c); SELECT 4 AS id, @p AS promedio, @c AS clasificacion;
CALL sp_clasificar_estudiante(5, @p, @c); SELECT 5 AS id, @p AS promedio, @c AS clasificacion;
SELECT IdEstudiante, Nombre, Apellido, Promedio, EstadoAcademico FROM Estudiante;
UPDATE Matricula SET NotaFinal = 3.8 WHERE IdEstudiante = 5 AND IdCurso = 1;
CALL sp_clasificar_estudiante(5, @p, @c); SELECT 5 AS id, @p AS promedio, @c AS clasificacion;
CALL sp_clasificar_estudiante(99, @p, @c);
-- ===== ACTIVIDAD 3 =====
SELECT IdEstudiante, fn_formatear_nombre(Nombre, Apellido) AS NombreCompleto, FechaNacimiento, fn_calcular_edad(FechaNacimiento) AS Edad FROM Estudiante ORDER BY NombreCompleto;
SELECT fn_calcular_edad('2000-01-15') AS edad, fn_formatear_nombre('  maría ', 'lópez ') AS nombre;
SELECT fn_formatear_nombre(Nombre, Apellido) AS Estudiante, fn_calcular_edad(FechaNacimiento) AS Edad FROM Estudiante WHERE fn_calcular_edad(FechaNacimiento) >= 23 ORDER BY Edad DESC;
SELECT fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, c.Nombre AS Curso, m.NotaFinal FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante JOIN Curso c ON c.IdCurso = m.IdCurso WHERE m.NotaFinal IS NOT NULL ORDER BY Estudiante LIMIT 5;
-- ===== ACTIVIDAD 4 =====
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, m.NotaFinal, m.Estado FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante WHERE m.IdCurso = 3 ORDER BY m.IdMatricula;
CALL sp_actualizar_estados_curso(3, @n); SELECT @n AS matriculas_procesadas;
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, m.NotaFinal, m.Estado FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante WHERE m.IdCurso = 3 ORDER BY m.IdMatricula;
SELECT c.Nombre AS Curso, m.Estado, COUNT(*) AS Cantidad FROM Matricula m JOIN Curso c ON c.IdCurso = m.IdCurso GROUP BY c.Nombre, m.Estado ORDER BY c.Nombre, m.Estado;
-- ===== ACTIVIDAD 5 =====
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES (2, 4, CURDATE(), 4.5);
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES (1, 4, CURDATE(), 5.5);
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES (1, 4, CURDATE(), -1.0);
UPDATE Matricula SET NotaFinal = 7.0 WHERE IdMatricula = 1;
UPDATE Matricula SET NotaFinal = 4.9 WHERE IdMatricula = 1;
SELECT IdMatricula, NotaFinal FROM Matricula WHERE IdMatricula = 1;
SELECT * FROM Auditoria_Matricula;
SHOW TRIGGERS;
