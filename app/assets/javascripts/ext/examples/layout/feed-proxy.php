<?php
// this is an example server-side proxy to load feeds
$feed = $_REQUEST['feed'];
if($feed != '' && strpos($feed, 'http') === 0){
	header('Content-Type: text/xml');
	readfile($feed);
	return;
}
?>