<?
require('Pusher.php');

header('Content-Type: application/json');
$key = "KEY";
$secret = "SECRET";
$app_id = "331";
$pusher = new Pusher($key, $secret, $app_id);
$presence_data = array('user_id' => '1', 'name' => 'Shawn');
echo $pusher->presence_auth($_POST['channel_name'], $_POST['socket_id'], '1', $presence_data);
?>