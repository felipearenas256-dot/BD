-- =====================================================================
-- PRACTICA 5 - CONSULTAS DE DEMOSTRACION (ejecutar DESPUES de practica5.sql)
-- mysql -h 127.0.0.1 -u root -p'RootLab_P4_2026!' universidad_umb
-- =====================================================================
USE universidad_umb;

-- ---------- 0. Ver los objetos creados en la practica ----------
SHOW PROCEDURE STATUS WHERE Db = 'universidad_umb';
SHOW FUNCTION STATUS  WHERE Db = 'universidad_umb';
SHOW TRIGGERS FROM universidad_umb;

-- ---------- ACTIVIDAD 1: sp_registrar_matricula ----------
-- Caso nuevo valido: Laura (1) en Ingenieria de Software (4)
CALL sp_registrar_matricula(1, 4, @msg);  SELECT @msg AS resultado;
-- Repetirlo -> lo rechaza por duplicado
CALL sp_registrar_matricula(1, 4, @msg);  SELECT @msg AS resultado;
-- Comprobar que quedo guardada con la fecha de hoy
SELECT * FROM Matricula WHERE IdEstudiante = 1 AND IdCurso = 4;

-- ---------- ACTIVIDAD 2: sp_clasificar_estudiante ----------
-- Julian (4) esta REPROBADO; se le suben las notas y se reclasifica
CALL sp_clasificar_estudiante(4, @prom, @clas);  SELECT @prom AS promedio_antes, @clas AS clasificacion_antes;
UPDATE Matricula SET NotaFinal = 4.5 WHERE IdEstudiante = 4 AND IdCurso IN (1, 2, 3);
CALL sp_clasificar_estudiante(4, @prom, @clas);  SELECT @prom AS promedio_despues, @clas AS clasificacion_despues;
SELECT IdEstudiante, Nombre, Promedio, EstadoAcademico FROM Estudiante WHERE IdEstudiante = 4;
-- Estudiante inexistente -> ERROR 1644: El estudiante no existe.
CALL sp_clasificar_estudiante(99, @prom, @clas);

-- ---------- ACTIVIDAD 3: funciones (UDF) ----------
-- Llamadas directas con valores sueltos
SELECT fn_calcular_edad('2000-01-15')            AS edad,
       fn_formatear_nombre('  maría ', 'lópez ') AS nombre_formateado;
-- Usadas en un WHERE: estudiantes de 23 anos o mas
SELECT fn_formatear_nombre(Nombre, Apellido) AS estudiante, fn_calcular_edad(FechaNacimiento) AS edad
FROM Estudiante
WHERE fn_calcular_edad(FechaNacimiento) >= 23
ORDER BY edad DESC;

-- ---------- ACTIVIDAD 4: cursor sp_actualizar_estados_curso ----------
-- Curso 2 (POO) ANTES
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS estudiante, m.NotaFinal, m.Estado
FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante WHERE m.IdCurso = 2;
CALL sp_actualizar_estados_curso(2, @n);  SELECT @n AS matriculas_procesadas;
-- Curso 2 DESPUES
SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS estudiante, m.NotaFinal, m.Estado
FROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante WHERE m.IdCurso = 2;
-- Resumen de estados de todas las matriculas despues de procesar los cursos 1, 2 y 3
CALL sp_actualizar_estados_curso(3, @n);
SELECT Estado, COUNT(*) AS cantidad FROM Matricula GROUP BY Estado;

-- ---------- ACTIVIDAD 5: triggers ----------
-- a) Nota valida -> se inserta y queda en la auditoria
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES (2, 4, CURDATE(), 4.5);
-- b) Nota invalida -> ERROR 1644: La nota debe estar entre 0.0 y 5.0
INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal) VALUES (3, 4, CURDATE(), 6.0);
-- c) Modificar una nota a un valor invalido -> ERROR 1644 (trigger BEFORE UPDATE)
UPDATE Matricula SET NotaFinal = 9.9 WHERE IdMatricula = 2;
-- d) La nota de la matricula 2 sigue intacta
SELECT IdMatricula, NotaFinal FROM Matricula WHERE IdMatricula = 2;
-- e) Auditoria: cada matricula nueva (INSERT directo o via SP) quedo registrada
SELECT a.IdAuditoria, a.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS estudiante,
       c.Nombre AS curso, a.Accion, a.Usuario, a.FechaHora
FROM Auditoria_Matricula a
JOIN Estudiante e ON e.IdEstudiante = a.IdEstudiante
JOIN Curso c      ON c.IdCurso      = a.IdCurso
ORDER BY a.IdAuditoria;
