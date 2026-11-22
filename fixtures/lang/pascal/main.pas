{ a brace comment (* with the other inside
  still open }
(* the other
   { a brace } still open
*)
{$mode objfpc}{$H+}
WriteLn('{ not a comment');
WriteLn('\'); // trailing
