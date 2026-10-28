<?php
/* Adminer con inicio de sesion automatico (root / universidad_umb) */
if (!isset($_GET['server'])) {
    header('Location: avanzado.php?lang=en&server=127.0.0.1&username=root&db=universidad_umb');
    exit;
}
function adminer_object() {
    class AdminerAuto extends Adminer {
        function name() { return 'Práctica 5'; }
        function credentials() { return ['127.0.0.1', 'root', 'RootLab_P4_2026!']; }
        function login($login, $password) { return true; }
        function databases($flush = true) { return ['universidad_umb']; }
    }
    return new AdminerAuto;
}
/* Si aun no hay sesion, se envia el login automaticamente */
if (empty($_COOKIE['adminer_sid']) && empty($_POST['auth'])) {
    $_POST['auth'] = ['driver' => 'server', 'server' => '127.0.0.1', 'username' => 'root',
                      'password' => 'RootLab_P4_2026!', 'db' => 'universidad_umb'];
}
include __DIR__ . '/adminer.php';
