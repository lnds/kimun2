<?php
# hash comment
#[Attribute]
//[x] not a comment
$s = <<<SQL
  /* text */
  SQL;
$t = 'it\'s'; // trailing
/* block
*/
