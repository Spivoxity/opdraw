(* oplex.mll *)
(* Copyright (c) 2021 J. M. Spivey *)

{
open Opgram
open Print
open Optree

let fname = ref "standard input"
let lnum = ref 1

(* |make_hash n [(x1, y1); ...]| creates a hash table of size |n|
   that initially contains the pairs |(x1, y1)|, ... *)
let make_hash n ps = 
  let table = Hashtbl.create n in
  List.iter (function (x, y) -> Hashtbl.add table x y) ps;
  table

let kwtable =
  make_hash 10 [ ("tile", TILE Auto);
    ("tile.ulft", TILE (Dir "ulft"));
    ("tile.urt", TILE (Dir "urt"));
    ("tile.llft", TILE (Dir "llft"));
    ("tile.lrt", TILE (Dir "lrt"));
    ("tile.rt", TILE (Dir "rt"));
    ("tile.lft", TILE (Dir "lft"));
    ("untile", UNTILE) ]

let lookup s =
  try Hashtbl.find kwtable s with Not_found -> IDENT s

let end_of_file () =
  fprintf stderr "\"$\", line $: unexpected EOF\n" [fStr !fname; fNum !lnum];
  exit 1
}
       
rule token = parse
    ['a'-'z''0'-'9''=''.']+ as s  { lookup s }
  | '<'(['A'-'Z']+ as x) 	{ OPEN (sprintf "\\C{$}" [fStr x]) }
  | '<'(['A'-'Z']+ as x)' '+(['A'-'Z''a'-'z''_']+ as y)
       { OPEN (sprintf "\\C{$}\\,\\S{$}" [fStr x; fStr y]) }
  | '<'(['A'-'Z']+ as x)' '+(['0'-'9''-']+ as y)
       { OPEN (sprintf "\\C{$}\\,{$}" [fStr x; fStr y]) }
  | '['(['0'-'9']+ as s)']' 	{ TAG s }
  | '>' 			{ CLOSE }
  | ',' 			{ COMMA }
  | '"''"' 			{ IDENT "" }
  | [' ''\t']+ 			{ token lexbuf }
  | '\n' 			{ incr lnum; token lexbuf }
  | eof 			{ end_of_file () }
  | _ 				{ BADTOK }
