<?php
$file_log="spia-unidad.log";
if (isset($_GET['f'])){
    $file_log=$_GET['f'];
    if (stripos($file_log,".log")===FALSE){
        $file_log.=".log";
    }
}
if (!file_exists($file_log)){
    die("file not found...");
}
$file_length = filesize($file_log);
if (0 >= $file_length ) {
    die("file is empty ... ".$file_length);
}
$special_tag=htmlspecialchars("<");
$replace=[ "{$special_tag}pre>", "{$special_tag}/pre>" /*,"\n"*/ ,
    '[34m', '[31m', '[0m'];
$replacement=[ "<pre>","</pre>"/*,"<br/>"*/,
    '<span style="color:blue">',  '<span style="color:red">','</span>'];
try{
    $f = fopen($file_log, "r") or die("unable open file");
    $fread = fread($f, $file_length);
    echo str_replace( $replace, $replacement, nl2br( str_replace("<", $special_tag, $fread) ) );
    fclose($f);
}catch(Exception $e){ 
        die("Unable open file: ".$e->getMessage());
}
