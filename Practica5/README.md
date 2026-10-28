# Práctica 5 – Procedimientos Almacenados, Funciones, Cursores y Triggers

Universidad Manuela Beltrán · Teoría de Bases de Datos · Guía N.º 5
SGBD: MySQL 8.0 (probado en 8.0.46)

| Archivo | Contenido |
|---|---|
| `practica5.sql` | Script completo: esquema + datos (sección 0) y Actividades 1 a 5 con sus pruebas |
| `ejecutar_p5.sh` | Inicia MySQL en Codespaces y ejecuta `practica5.sql` |
| `ver_tablas.sh` | Abre el **panel web** de la práctica en el puerto 8080 |
| `panel/` | Código del panel (PHP) |
| `consultas_demo_p5.sql` | Consultas adicionales para demostrar cada actividad en clase |
| `salida_practica5.txt` | Resultado de ejecutar `practica5.sql` |
| `salida_demo_p5.txt` | Resultado de ejecutar `consultas_demo_p5.sql` |

## Cómo ejecutarlo en GitHub Codespaces

```bash
cd Practica5
bash ejecutar_p5.sh                                   # crea la BD y corre las 5 actividades
mysql -h 127.0.0.1 -u root -p'RootLab_P4_2026!' --force -t universidad_umb < consultas_demo_p5.sql
```

### Interfaz gráfica (panel web)

```bash
bash ver_tablas.sh
```
Clic en **Open in Browser** (o pestaña **PORTS** → 8080 → 🌐). **No pide usuario ni contraseña.**

| Sección del panel | Qué demuestra |
|---|---|
| Inicio | Conteo de filas, procedimientos, funciones y triggers creados |
| Ver tablas | Contenido de `Estudiante`, `Curso`, `Matricula`, `Auditoria_Matricula` |
| 1 · Registrar matrícula | `sp_registrar_matricula` con listas desplegables (incluye estudiante/curso 99) |
| 2 · Clasificar estudiante | `sp_clasificar_estudiante` para uno o para todos |
| 3 · Funciones (UDF) | `fn_calcular_edad` y `fn_formatear_nombre` en un SELECT y con valores propios |
| 4 · Cursor por curso | `sp_actualizar_estados_curso` con tablas ANTES / DESPUÉS |
| 5 · Triggers y auditoría | INSERT / UPDATE con notas válidas e inválidas + tabla de auditoría |
| Consulta libre | Cualquier SQL |
| Reiniciar base | Vuelve a ejecutar `practica5.sql` (datos originales) |
| Adminer (avanzado) | Administrador completo, con inicio de sesión automático |

Cada resultado muestra el **SQL ejecutado**, listo para las capturas del informe.

Los `ERROR 1644 (45000): La nota debe estar entre 0.0 y 5.0` son **esperados**: demuestran que el trigger rechaza notas inválidas.

> ⚠️ `practica5.sql` borra y recrea `universidad_umb`. Si luego quieres volver a demostrar la Práctica 4, vuelve a ejecutar su `ejecutar.sh`.

## Datos de prueba

| Tabla | Filas |
|---|---|
| Estudiante | 30 (los 5 originales de la guía + 25 nuevos) |
| Curso | 15 (4 originales + 11 nuevos) |
| Matricula | 109 iniciales (13 originales + 96 nuevas) |

Los registros originales de la guía (estudiantes 1–5, cursos 1–4 y sus 13 matrículas) no cambian, por eso las pruebas de las actividades dan los mismos resultados del informe. Al clasificar a los 30 estudiantes salen 5 EXCELENTE, 8 BUENO, 9 APROBADO, 6 REPROBADO y 2 SIN NOTAS.

## Objetos creados

| Tipo | Nombre | Qué hace |
|---|---|---|
| Procedimiento | `sp_registrar_matricula` | Matricula validando estudiante, curso y duplicados; mensaje en `OUT p_mensaje` |
| Procedimiento | `sp_clasificar_estudiante` | Calcula el promedio y clasifica: EXCELENTE / BUENO / APROBADO / REPROBADO / SIN NOTAS |
| Función | `fn_calcular_edad` | Edad en años cumplidos |
| Función | `fn_formatear_nombre` | `APELLIDO, NOMBRE` en mayúsculas |
| Procedimiento (cursor) | `sp_actualizar_estados_curso` | Recorre las matrículas de un curso y pone APROBADO / REPROBADO / EN CURSO |
| Trigger | `trg_matricula_valida_nota` | BEFORE INSERT: nota entre 0.0 y 5.0 |
| Trigger | `trg_matricula_valida_nota_upd` | BEFORE UPDATE: misma validación |
| Trigger | `trg_matricula_auditoria` | AFTER INSERT: registra la matrícula en `Auditoria_Matricula` |

## Resultados obtenidos

| Actividad | Prueba | Resultado |
|---|---|---|
| 1 | `CALL sp_registrar_matricula(5, 2, @msg)` | `OK: matrícula 110 registrada …` |
| 1 | Estudiante 99 / curso 99 / duplicado | Mensajes `ERROR: …` en `@msg` |
| 2 | Estudiantes 1–5 | EXCELENTE 4.60 · BUENO 4.07 · APROBADO 3.20 · REPROBADO 2.63 · SIN NOTAS |
| 3 | `SELECT` con las UDF | `GÓMEZ, LAURA` 23 años, etc. |
| 4 | Curso 1 | 5 procesadas: 3 APROBADO, 1 REPROBADO, 1 EN CURSO |
| 5 | Notas 5.5, -1.0 y UPDATE a 7.0 | ERROR 1644 (rechazadas por el trigger) |
| 5 | Inserción válida + SP | 2 filas en `Auditoria_Matricula` |
