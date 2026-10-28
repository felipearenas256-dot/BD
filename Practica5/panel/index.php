<?php
/* =====================================================================
   PRACTICA 5 - Panel web para demostrar la guia
   Procedimientos almacenados, funciones, cursores y triggers (MySQL 8)
   Se abre con:  bash ver_tablas.sh   (puerto 8080)
   ===================================================================== */
const DB_HOST = '127.0.0.1';
const DB_USER = 'root';
const DB_PASS = 'RootLab_P4_2026!';
const DB_NAME = 'universidad_umb';

mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);

function db(): mysqli {
    static $c = null;
    if ($c === null) {
        $c = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
        $c->set_charset('utf8mb4');
    }
    return $c;
}

function h($v): string { return htmlspecialchars((string)$v, ENT_QUOTES, 'UTF-8'); }

/* Ejecuta una o varias sentencias y devuelve todos los resultados */
function run(string $sql): array {
    $out = ['sql' => trim($sql), 'sets' => [], 'error' => null, 'afectadas' => 0];
    try {
        $c = db();
        $c->multi_query($sql);
        do {
            if ($r = $c->store_result()) {
                $cols = array_map(fn($f) => $f->name, $r->fetch_fields());
                $out['sets'][] = ['cols' => $cols, 'rows' => $r->fetch_all(MYSQLI_NUM)];
                $r->free();
            } elseif ($c->affected_rows > 0) {
                $out['afectadas'] += $c->affected_rows;
            }
        } while ($c->more_results() && $c->next_result());
    } catch (mysqli_sql_exception $e) {
        $out['error'] = 'ERROR ' . $e->getCode() . ': ' . $e->getMessage();
        try { while (db()->more_results() && db()->next_result()) {} } catch (Throwable $t) {}
    }
    return $out;
}

/* Valor simple (primera celda) */
function val(string $sql) {
    $r = run($sql);
    return $r['sets'][0]['rows'][0][0] ?? null;
}

function lista(string $sql): array {
    $r = run($sql);
    return $r['sets'][0]['rows'] ?? [];
}

const BADGES = ['EXCELENTE' => 'ok', 'BUENO' => 'info', 'APROBADO' => 'ok2', 'REPROBADO' => 'bad',
                'SIN NOTAS' => 'gray', 'EN CURSO' => 'gray', 'INSERT' => 'info'];

function celda($v): string {
    if ($v === null) return '<span class="null">NULL</span>';
    if (isset(BADGES[$v])) return '<span class="badge ' . BADGES[$v] . '">' . h($v) . '</span>';
    if (str_starts_with((string)$v, 'OK:'))    return '<span class="msg ok">' . h($v) . '</span>';
    if (str_starts_with((string)$v, 'ERROR:')) return '<span class="msg bad">' . h($v) . '</span>';
    return h($v);
}

function tabla(array $set, string $titulo = ''): string {
    $html = $titulo ? '<div class="ttl">' . h($titulo) . '</div>' : '';
    if (!$set['rows']) return $html . '<p class="vacio">Sin filas.</p>';
    $html .= '<div class="tw"><table><thead><tr>';
    foreach ($set['cols'] as $c) $html .= '<th>' . h($c) . '</th>';
    $html .= '</tr></thead><tbody>';
    foreach ($set['rows'] as $row) {
        $html .= '<tr>';
        foreach ($row as $v) $html .= '<td>' . celda($v) . '</td>';
        $html .= '</tr>';
    }
    return $html . '</tbody></table></div><div class="cnt">' . count($set['rows']) . ' fila(s)</div>';
}

/* Muestra el SQL ejecutado + resultados + error */
function mostrar(array $r, string $titulo = 'Resultado'): string {
    $html = '<div class="res"><div class="res-h">' . h($titulo) . '</div>';
    $html .= '<details open><summary>SQL ejecutado</summary><pre>' . h($r['sql']) . '</pre></details>';
    if ($r['error']) $html .= '<div class="alert bad">⛔ ' . h($r['error']) . '</div>';
    foreach ($r['sets'] as $s) $html .= tabla($s);
    if (!$r['error'] && !$r['sets']) $html .= '<div class="alert ok">✔ Ejecutado. Filas afectadas: ' . $r['afectadas'] . '</div>';
    return $html . '</div>';
}

function opciones(array $rows, $sel, array $extra = []): string {
    $o = '';
    foreach ($rows as $r) $o .= '<option value="' . h($r[0]) . '"' . ((string)$sel === (string)$r[0] ? ' selected' : '') . '>' . h($r[0] . ' – ' . $r[1]) . '</option>';
    foreach ($extra as $k => $t) $o .= '<option value="' . h($k) . '"' . ((string)$sel === (string)$k ? ' selected' : '') . '>' . h($t) . '</option>';
    return $o;
}

/* ---------------------------------------------------------------- */
$p   = $_GET['p'] ?? 'inicio';
$req = $_POST + $_GET;
$out = '';

try { db(); $conectado = true; } catch (Throwable $e) { $conectado = false; $errCon = $e->getMessage(); }

if ($conectado) {
    $baseOk = (int) val("SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA='" . DB_NAME . "' AND TABLE_NAME='Matricula'") === 1;
} else { $baseOk = false; }

/* Reiniciar la base ejecutando practica5.sql con el cliente mysql */
if ($p === 'reiniciar' && ($_POST['go'] ?? '') === '1') {
    $script = realpath(__DIR__ . '/../practica5.sql');
    $cmd = 'mysql -h ' . escapeshellarg(DB_HOST) . ' -u ' . escapeshellarg(DB_USER) . ' -p' . escapeshellarg(DB_PASS)
         . ' --default-character-set=utf8mb4 --force < ' . escapeshellarg($script) . ' 2>&1';
    $salida = shell_exec($cmd) ?? '';
    $salida = trim(preg_replace('/^.*Using a password.*\n?/m', '', $salida));
    $reinicio = $salida;
    $baseOk = true;
}

$menu = [
    'inicio' => ['🏠', 'Inicio'],
    'tablas' => ['📋', 'Ver tablas'],
    'a1'     => ['1', 'Registrar matrícula'],
    'a2'     => ['2', 'Clasificar estudiante'],
    'a3'     => ['3', 'Funciones (UDF)'],
    'a4'     => ['4', 'Cursor por curso'],
    'a5'     => ['5', 'Triggers y auditoría'],
    'sql'    => ['⌨', 'Consulta libre'],
    'reiniciar' => ['↺', 'Reiniciar base'],
];
?>
<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Práctica 5 – Panel</title>
<style>
:root{
  --bg:#f5f6f8; --card:#fff; --tx:#1f2430; --mut:#6b7280; --bd:#e5e7eb;
  --pri:#2563eb; --pri2:#eff4ff; --side:#111827; --sidetx:#cbd5e1;
  --ok:#15803d; --okbg:#e8f6ed; --bad:#b91c1c; --badbg:#fdecec;
  --info:#1d4ed8; --infobg:#e8efff; --gray:#4b5563; --graybg:#eef0f3; --ok2:#0f766e; --ok2bg:#e3f5f2;
}
*{box-sizing:border-box}
body{margin:0;font:15px/1.5 system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;background:var(--bg);color:var(--tx)}
.app{display:flex;min-height:100vh}
aside{width:240px;background:var(--side);color:var(--sidetx);padding:20px 12px;flex-shrink:0}
aside .logo{color:#fff;font-weight:700;font-size:17px;padding:0 10px 4px}
aside .sub{font-size:12px;color:#94a3b8;padding:0 10px 18px}
aside a{display:flex;gap:10px;align-items:center;color:var(--sidetx);text-decoration:none;padding:9px 10px;border-radius:8px;margin-bottom:2px}
aside a:hover{background:#1f2937;color:#fff}
aside a.on{background:var(--pri);color:#fff}
aside .ic{width:24px;height:24px;border-radius:6px;background:#1f2937;display:grid;place-items:center;font-size:13px;font-weight:700}
aside a.on .ic{background:rgba(255,255,255,.2)}
main{flex:1;padding:28px 32px;max-width:1100px}
h1{font-size:24px;margin:0 0 4px}
.lead{color:var(--mut);margin:0 0 22px}
.card{background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:20px;margin-bottom:18px}
.card h2{font-size:16px;margin:0 0 12px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:14px}
.stat{background:var(--card);border:1px solid var(--bd);border-radius:12px;padding:16px}
.stat b{display:block;font-size:28px}
.stat span{color:var(--mut);font-size:13px}
form.row{display:flex;flex-wrap:wrap;gap:12px;align-items:flex-end}
label{display:flex;flex-direction:column;font-size:13px;color:var(--mut);gap:4px}
select,input,textarea{font:inherit;padding:9px 11px;border:1px solid var(--bd);border-radius:8px;background:#fff;color:var(--tx);min-width:180px}
textarea{width:100%;min-height:150px;font-family:ui-monospace,Consolas,monospace;font-size:14px}
button{font:inherit;font-weight:600;padding:9px 16px;border:0;border-radius:8px;background:var(--pri);color:#fff;cursor:pointer}
button:hover{filter:brightness(.95)}
button.sec{background:var(--pri2);color:var(--pri)}
button.danger{background:var(--bad)}
.tabs{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:14px}
.tabs a{padding:7px 14px;border-radius:999px;background:var(--card);border:1px solid var(--bd);text-decoration:none;color:var(--tx);font-size:14px}
.tabs a.on{background:var(--pri);border-color:var(--pri);color:#fff}
.tw{overflow-x:auto;border:1px solid var(--bd);border-radius:10px}
table{border-collapse:collapse;width:100%;font-size:14px}
th{background:#f9fafb;text-align:left;font-weight:600;color:var(--mut);font-size:12px;text-transform:uppercase;letter-spacing:.03em}
th,td{padding:9px 12px;border-bottom:1px solid var(--bd);white-space:nowrap}
tr:last-child td{border-bottom:0}
.cnt{color:var(--mut);font-size:12px;margin:6px 2px 12px}
.ttl{font-weight:600;margin:8px 0 8px}
.null{color:#9ca3af;font-style:italic}
.badge{display:inline-block;padding:2px 9px;border-radius:999px;font-size:12px;font-weight:600}
.badge.ok{background:var(--okbg);color:var(--ok)} .badge.ok2{background:var(--ok2bg);color:var(--ok2)}
.badge.bad{background:var(--badbg);color:var(--bad)} .badge.info{background:var(--infobg);color:var(--info)}
.badge.gray{background:var(--graybg);color:var(--gray)}
.msg{font-weight:600} .msg.ok{color:var(--ok)} .msg.bad{color:var(--bad)}
.alert{padding:12px 14px;border-radius:10px;margin:10px 0;font-weight:500}
.alert.ok{background:var(--okbg);color:var(--ok)} .alert.bad{background:var(--badbg);color:var(--bad)}
.alert.info{background:var(--infobg);color:var(--info)}
.res{margin-top:16px}
.res-h{font-weight:700;margin-bottom:8px}
details{margin-bottom:10px}
summary{cursor:pointer;color:var(--mut);font-size:13px}
pre{background:#0f172a;color:#e2e8f0;padding:12px 14px;border-radius:10px;overflow-x:auto;font-size:13px;margin:6px 0 0;white-space:pre-wrap}
.two{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:16px}
.hint{color:var(--mut);font-size:13px;margin:10px 0 0}
ul.obj{margin:0;padding-left:18px} ul.obj li{margin:3px 0}
code{background:#f1f5f9;padding:1px 6px;border-radius:5px;font-size:13px}
@media (max-width:860px){.app{flex-direction:column}aside{width:100%;display:flex;flex-wrap:wrap;gap:4px;padding:12px}aside .logo,aside .sub{width:100%}main{padding:18px 16px}.two{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="app">
<aside>
  <div class="logo">Práctica 5</div>
  <div class="sub">SP · Funciones · Cursores · Triggers</div>
  <?php foreach ($menu as $k => [$ic, $t]): ?>
    <a href="?p=<?= $k ?>" class="<?= $p === $k ? 'on' : '' ?>"><span class="ic"><?= $ic ?></span><?= h($t) ?></a>
  <?php endforeach; ?>
  <a href="avanzado.php" target="_blank"><span class="ic">⚙</span>Adminer (avanzado)</a>
</aside>
<main>
<?php if (!$conectado): ?>
  <h1>No hay conexión con MySQL</h1>
  <div class="alert bad"><?= h($errCon) ?></div>
  <div class="card">En la terminal del Codespace ejecuta <code>bash ejecutar_p5.sh</code> y recarga esta página.</div>

<?php elseif (!$baseOk && $p !== 'reiniciar'): ?>
  <h1>La base de la Práctica 5 no existe</h1>
  <div class="card">Pulsa el botón para crearla con <code>practica5.sql</code>.
    <form method="post" action="?p=reiniciar" style="margin-top:12px"><input type="hidden" name="go" value="1"><button>Crear base de datos</button></form>
  </div>

<?php elseif ($p === 'inicio'): ?>
  <h1>Panel de la Práctica 5</h1>
  <p class="lead">Base <code><?= DB_NAME ?></code> · conectado como <code><?= DB_USER ?></code> · <?= h(val('SELECT VERSION()')) ?></p>
  <div class="grid">
    <?php foreach (['Estudiante','Curso','Matricula','Auditoria_Matricula'] as $t): ?>
      <a class="stat" href="?p=tablas&t=<?= $t ?>" style="text-decoration:none;color:inherit"><b><?= (int) val("SELECT COUNT(*) FROM `$t`") ?></b><span><?= $t ?></span></a>
    <?php endforeach; ?>
  </div>
  <div class="two" style="margin-top:18px">
    <div class="card"><h2>Procedimientos y funciones</h2><ul class="obj">
      <?php foreach (lista("SELECT ROUTINE_NAME, ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='" . DB_NAME . "' ORDER BY ROUTINE_TYPE DESC, ROUTINE_NAME") as [$n, $ty]): ?>
        <li><code><?= h($n) ?></code> <span class="badge <?= $ty === 'PROCEDURE' ? 'info' : 'ok2' ?>"><?= $ty === 'PROCEDURE' ? 'Procedimiento' : 'Función' ?></span></li>
      <?php endforeach; ?></ul></div>
    <div class="card"><h2>Triggers</h2><ul class="obj">
      <?php foreach (lista("SELECT TRIGGER_NAME, ACTION_TIMING, EVENT_MANIPULATION, EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='" . DB_NAME . "' ORDER BY TRIGGER_NAME") as [$n, $tm, $ev, $tb]): ?>
        <li><code><?= h($n) ?></code> <span class="badge gray"><?= h("$tm $ev · $tb") ?></span></li>
      <?php endforeach; ?></ul></div>
  </div>
  <div class="card"><h2>Cómo usar este panel</h2>
    Cada actividad de la guía tiene su sección en el menú izquierdo. Elige los valores, pulsa el botón y verás el resultado junto con el <b>SQL ejecutado</b>, listo para la captura del informe. Si quieres volver a los datos originales, usa <b>Reiniciar base</b>.
  </div>

<?php elseif ($p === 'tablas'):
  $tablas = ['Estudiante','Curso','Matricula','Auditoria_Matricula'];
  $t = in_array($req['t'] ?? '', $tablas, true) ? $req['t'] : 'Estudiante'; ?>
  <h1>Ver tablas</h1>
  <p class="lead">Contenido actual de cada tabla.</p>
  <div class="tabs"><?php foreach ($tablas as $x): ?><a class="<?= $x === $t ? 'on' : '' ?>" href="?p=tablas&t=<?= $x ?>"><?= $x ?></a><?php endforeach; ?></div>
  <div class="card"><?= mostrar(run("SELECT * FROM `$t`;"), $t) ?></div>

<?php elseif ($p === 'a1'):
  $est = lista('SELECT IdEstudiante, CONCAT(Nombre," ",Apellido) FROM Estudiante ORDER BY IdEstudiante');
  $cur = lista('SELECT IdCurso, Nombre FROM Curso ORDER BY IdCurso');
  $e = (int)($req['e'] ?? 1); $c = (int)($req['c'] ?? 4); ?>
  <h1>Actividad 1 · Registrar matrícula</h1>
  <p class="lead"><code>sp_registrar_matricula(IN estudiante, IN curso, OUT mensaje)</code> valida que existan el estudiante y el curso y que no esté ya matriculado.</p>
  <div class="card">
    <form class="row" method="post" action="?p=a1">
      <label>Estudiante<select name="e"><?= opciones($est, $e, ['99' => '99 – (no existe)']) ?></select></label>
      <label>Curso<select name="c"><?= opciones($cur, $c, ['99' => '99 – (no existe)']) ?></select></label>
      <button name="go" value="1">Registrar matrícula</button>
    </form>
    <p class="hint">Prueba los 4 casos de la guía: uno válido, estudiante 99, curso 99 y repetir una matrícula existente.</p>
    <?php if (isset($_POST['go'])): ?>
      <?= mostrar(run("CALL sp_registrar_matricula($e, $c, @msg);\nSELECT @msg AS mensaje;"), 'Respuesta del procedimiento') ?>
      <?= mostrar(run("SELECT m.IdMatricula, c.Nombre AS Curso, m.FechaMatricula, m.NotaFinal, m.Estado\nFROM Matricula m JOIN Curso c ON c.IdCurso = m.IdCurso\nWHERE m.IdEstudiante = $e ORDER BY m.IdMatricula;"), 'Matrículas del estudiante ' . $e) ?>
    <?php endif; ?>
  </div>

<?php elseif ($p === 'a2'):
  $est = lista('SELECT IdEstudiante, CONCAT(Nombre," ",Apellido) FROM Estudiante ORDER BY IdEstudiante');
  $e = (int)($req['e'] ?? 1); ?>
  <h1>Actividad 2 · Clasificar estudiante</h1>
  <p class="lead">Calcula el promedio y clasifica: <span class="badge ok">EXCELENTE</span> ≥ 4.5 · <span class="badge info">BUENO</span> ≥ 4.0 · <span class="badge ok2">APROBADO</span> ≥ 3.0 · <span class="badge bad">REPROBADO</span> &lt; 3.0</p>
  <div class="card">
    <form class="row" method="post" action="?p=a2">
      <label>Estudiante<select name="e"><?= opciones($est, $e, ['99' => '99 – (no existe)']) ?></select></label>
      <button name="go" value="uno">Clasificar</button>
      <button class="sec" name="go" value="todos">Clasificar a todos</button>
    </form>
    <?php if (($_POST['go'] ?? '') === 'uno'): ?>
      <?= mostrar(run("CALL sp_clasificar_estudiante($e, @prom, @clas);\nSELECT $e AS IdEstudiante, @prom AS promedio, @clas AS clasificacion;"), 'Resultado') ?>
    <?php elseif (($_POST['go'] ?? '') === 'todos'):
      $sql = ''; foreach ($est as [$id]) $sql .= "CALL sp_clasificar_estudiante($id, @prom, @clas); SELECT $id AS IdEstudiante, @prom AS promedio, @clas AS clasificacion;\n";
      $r = run($sql); $todas = ['cols' => $r['sets'][0]['cols'] ?? [], 'rows' => array_merge(...array_map(fn($s) => $s['rows'], $r['sets'] ?: [['rows' => []]]))];
      $r['sets'] = [$todas]; ?>
      <?= mostrar($r, 'Todos los estudiantes') ?>
    <?php endif; ?>
  </div>
  <div class="card"><?= mostrar(run('SELECT IdEstudiante, Nombre, Apellido, Promedio, EstadoAcademico FROM Estudiante;'), 'Tabla Estudiante (se actualiza con el procedimiento)') ?></div>

<?php elseif ($p === 'a3'):
  $f = $req['f'] ?? '2000-01-15'; $n = $req['n'] ?? '  maría '; $a = $req['a'] ?? 'lópez '; ?>
  <h1>Actividad 3 · Funciones definidas por el usuario</h1>
  <p class="lead"><code>fn_calcular_edad(fecha)</code> y <code>fn_formatear_nombre(nombre, apellido)</code> se usan dentro de un <code>SELECT</code> como cualquier columna.</p>
  <div class="card">
    <?= mostrar(run("SELECT IdEstudiante,\n       fn_formatear_nombre(Nombre, Apellido) AS NombreCompleto,\n       FechaNacimiento,\n       fn_calcular_edad(FechaNacimiento)     AS Edad\nFROM Estudiante\nORDER BY NombreCompleto;"), 'Funciones aplicadas a la tabla Estudiante') ?>
  </div>
  <div class="card"><h2>Probar con tus propios valores</h2>
    <form class="row" method="post" action="?p=a3">
      <label>Fecha de nacimiento<input type="date" name="f" value="<?= h($f) ?>"></label>
      <label>Nombre<input name="n" value="<?= h($n) ?>"></label>
      <label>Apellido<input name="a" value="<?= h($a) ?>"></label>
      <button name="go" value="1">Calcular</button>
    </form>
    <?php if (isset($_POST['go'])): $c = db(); ?>
      <?= mostrar(run("SELECT fn_calcular_edad('" . $c->real_escape_string($f) . "') AS edad,\n       fn_formatear_nombre('" . $c->real_escape_string($n) . "', '" . $c->real_escape_string($a) . "') AS nombre_formateado;"), 'Resultado') ?>
    <?php endif; ?>
  </div>

<?php elseif ($p === 'a4'):
  $cur = lista('SELECT IdCurso, Nombre FROM Curso ORDER BY IdCurso');
  $c = (int)($req['c'] ?? 2);
  $q = "SELECT m.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante, m.NotaFinal, m.Estado\nFROM Matricula m JOIN Estudiante e ON e.IdEstudiante = m.IdEstudiante\nWHERE m.IdCurso = $c ORDER BY m.IdMatricula;"; ?>
  <h1>Actividad 4 · Procedimiento con cursor</h1>
  <p class="lead"><code>sp_actualizar_estados_curso</code> recorre fila a fila las matrículas del curso: nota ≥ 3.0 → <span class="badge ok2">APROBADO</span>, &lt; 3.0 → <span class="badge bad">REPROBADO</span>, sin nota → <span class="badge gray">EN CURSO</span>.</p>
  <div class="card">
    <form class="row" method="post" action="?p=a4">
      <label>Curso<select name="c"><?= opciones($cur, $c) ?></select></label>
      <button name="go" value="1">Ejecutar cursor</button>
    </form>
    <?php if (isset($_POST['go'])):
      $antes = run($q);
      $call  = run("CALL sp_actualizar_estados_curso($c, @n);\nSELECT @n AS matriculas_procesadas;");
      $desp  = run($q); ?>
      <?= mostrar($call, 'Ejecución del procedimiento') ?>
      <div class="two"><div><?= mostrar($antes, 'ANTES') ?></div><div><?= mostrar($desp, 'DESPUÉS') ?></div></div>
    <?php else: ?>
      <?= mostrar(run($q), 'Estado actual del curso') ?>
    <?php endif; ?>
  </div>

<?php elseif ($p === 'a5'):
  $est = lista('SELECT IdEstudiante, CONCAT(Nombre," ",Apellido) FROM Estudiante ORDER BY IdEstudiante');
  $cur = lista('SELECT IdCurso, Nombre FROM Curso ORDER BY IdCurso');
  $mat = lista('SELECT m.IdMatricula, CONCAT(e.Nombre," · ",c.Nombre," · nota ",IFNULL(m.NotaFinal,"—")) FROM Matricula m JOIN Estudiante e ON e.IdEstudiante=m.IdEstudiante JOIN Curso c ON c.IdCurso=m.IdCurso ORDER BY m.IdMatricula');
  $e = (int)($req['e'] ?? 3); $c = (int)($req['c'] ?? 4); $nota = $req['nota'] ?? '5.5';
  $m = (int)($req['m'] ?? 1); $nota2 = $req['nota2'] ?? '7.0';
  $sqlNota = fn($x) => trim($x) === '' ? 'NULL' : (string)(float)str_replace(',', '.', $x); ?>
  <h1>Actividad 5 · Triggers</h1>
  <p class="lead"><code>BEFORE INSERT</code> y <code>BEFORE UPDATE</code> rechazan notas fuera de 0.0–5.0 · <code>AFTER INSERT</code> registra cada matrícula nueva en <code>Auditoria_Matricula</code>.</p>
  <div class="two">
    <div class="card"><h2>Insertar matrícula con nota</h2>
      <form method="post" action="?p=a5" style="display:grid;gap:10px">
        <label>Estudiante<select name="e"><?= opciones($est, $e) ?></select></label>
        <label>Curso<select name="c"><?= opciones($cur, $c) ?></select></label>
        <label>Nota (válida: 4.5 · inválida: 5.5 o -1)<input name="nota" value="<?= h($nota) ?>"></label>
        <button name="go" value="ins">Insertar</button>
      </form>
      <p class="hint">Para un caso válido elige una combinación nueva, p. ej. <b>Andrés + Ingeniería de Software</b> con nota 4.5.</p>
    </div>
    <div class="card"><h2>Cambiar la nota de una matrícula</h2>
      <form method="post" action="?p=a5" style="display:grid;gap:10px">
        <label>Matrícula<select name="m"><?= opciones($mat, $m) ?></select></label>
        <label>Nueva nota (prueba 7.0)<input name="nota2" value="<?= h($nota2) ?>"></label>
        <button name="go" value="upd">Actualizar nota</button>
      </form>
    </div>
  </div>
  <?php if (($_POST['go'] ?? '') === 'ins'): ?>
    <div class="card"><?= mostrar(run("INSERT INTO Matricula (IdEstudiante, IdCurso, FechaMatricula, NotaFinal)\nVALUES ($e, $c, CURDATE(), " . $sqlNota($nota) . ");"), 'Resultado del INSERT') ?></div>
  <?php elseif (($_POST['go'] ?? '') === 'upd'): ?>
    <div class="card"><?= mostrar(run("UPDATE Matricula SET NotaFinal = " . $sqlNota($nota2) . " WHERE IdMatricula = $m;"), 'Resultado del UPDATE') ?></div>
  <?php endif; ?>
  <div class="card"><?= mostrar(run("SELECT a.IdAuditoria, a.IdMatricula, fn_formatear_nombre(e.Nombre, e.Apellido) AS Estudiante,\n       c.Nombre AS Curso, a.Accion, a.Usuario, a.FechaHora\nFROM Auditoria_Matricula a\nJOIN Estudiante e ON e.IdEstudiante = a.IdEstudiante\nJOIN Curso c      ON c.IdCurso      = a.IdCurso\nORDER BY a.IdAuditoria;"), 'Tabla Auditoria_Matricula') ?></div>

<?php elseif ($p === 'sql'):
  $q = $_POST['q'] ?? "CALL sp_registrar_matricula(2, 4, @msg);\nSELECT @msg;"; ?>
  <h1>Consulta libre</h1>
  <p class="lead">Escribe cualquier sentencia SQL. Puedes poner varias separadas por <code>;</code>.</p>
  <div class="card">
    <form method="post" action="?p=sql">
      <textarea name="q" spellcheck="false"><?= h($q) ?></textarea>
      <div style="margin-top:10px"><button name="go" value="1">Ejecutar</button></div>
    </form>
    <p class="hint">Para crear procedimientos con <code>DELIMITER</code> usa la terminal; aquí no hace falta <code>DELIMITER</code>.</p>
    <?php if (isset($_POST['go'])): ?><?= mostrar(run($q)) ?><?php endif; ?>
  </div>

<?php elseif ($p === 'reiniciar'): ?>
  <h1>Reiniciar base</h1>
  <p class="lead">Vuelve a ejecutar <code>practica5.sql</code>: borra y recrea <code><?= DB_NAME ?></code> con los datos originales de la guía.</p>
  <div class="card">
    <?php if (isset($reinicio)): ?>
      <div class="alert ok">✔ Base recreada. Los ERROR 1644 de abajo son las pruebas de la Actividad 5 (esperados).</div>
      <pre><?= h($reinicio) ?></pre>
    <?php else: ?>
      <form method="post" action="?p=reiniciar"><input type="hidden" name="go" value="1"><button class="danger">Reiniciar base de datos</button></form>
    <?php endif; ?>
  </div>
<?php endif; ?>
</main>
</div>
</body>
</html>
