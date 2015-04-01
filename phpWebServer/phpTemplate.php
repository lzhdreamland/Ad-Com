<?php
/*Simple Service
This is just a simple php script that will return values ,the 
method is selected using the value of HTTP_METHOD
*/
if ($_SERVER['HTTP_METHOD'] === 'getValues'){
 //just return some test values
   $data['value1'] = 1;
   $data['value2'] = "Hello php service world";
   echo json_encode($data);
}
else if ($_SERVER['HTTP_METHOD'] === 'postValues'){ 
   $body;
   /*Sometimes the body data is attached in raw form and is not attached 
   to $_POST, this needs to be handled*/
   if($_POST == null){
      $handle  = fopen('php://input', 'r');
      $rawData = fgets($handle);
      $body = json_decode($rawData);
   }
   else{
      $body == $_POST;
   }
   echo json_encode($body);//just return the post you sent it for testing purposes
}
else {
   $data['error'] = 'The Service you asked for was not recognized';
   echo json_encode($data);
}

?>