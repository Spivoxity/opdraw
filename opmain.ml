(* opmain.ml *)
(* Copyright (c) 2021 J. M. Spivey *)

open Print
open Optree

let delta = Hashtbl.create 100

let rec set_delta n d = 
  Hashtbl.add delta n d

let rec find_gap p1 p2 =
  match (p1, p2) with
      ([], _) -> 0.0
    | (_, []) -> 0.0
    | ((_, y1) :: q1, (x2, _) :: q2) ->
        max (y1+.x2) (find_gap q1 q2)

let rec shift d = List.map (fun (x, y) -> (x-.d, y+.d))

let rec join d p1 p2 =
  match (p1, p2) with
      ([], _) -> shift d p2
    | (_, []) -> shift (-.d) p1
    | ((x1, _) :: q1, (_, y2) :: q2) ->
        (x1+.d, y2+.d) :: join d q1 q2

let rec layout =
  function
      Tile (spec, inst, reg, t) -> layout t
    | Untile t -> layout t
    | Node (n, op, []) -> [(0.0, 0.0)]
    | Node (n, op, [t]) -> (0.0, 0.0) :: layout t
    | Node (n, op, [t1; t2]) ->
        let p1 = layout t1 and p2 = layout t2 in
        let d = find_gap p1 p2 /. 2.0 +. 1.0 in
        set_delta n d;
        (0.0, 0.0) :: join d p1 p2
    | _ -> failwith "layout"   

let rec make_nodes x y =
  function
      Tile (spec, inst, reg, t) -> 
        make_nodes x y t
    | Untile t -> 
        make_nodes x y t
    | Node (n, op, kids) ->
        printf "node$($, $)(btex \\node{$} etex);\n" 
          [fNum n; fFlo x; fFlo y; fStr op];
        begin match kids with
            [] -> ()
          | [t] -> make_nodes x (y -. 1.0) t
          | [t1; t2] ->
              let d = Hashtbl.find delta n in
              make_nodes (x -. d) (y -. 1.0) t1;
              make_nodes (x +. d) (y -. 1.0) t2
          | _ -> failwith "make_nodes"   
        end

let rec make_links parent dir =
  function
      Tile (spec, inst, reg, t) ->
        make_links parent dir t
    | Untile t ->
        make_links parent dir t
    | Node (n, _, kids) ->
        if dir <> 'x' then 
          printf "link.$($, $);\n" [fChr dir; fNum parent; fNum n];
        begin match kids with
            [] -> ()
          | [t] -> make_links n 'v' t
          | [t1; t2] -> make_links n 'l' t1; make_links n 'r' t2
          | _ -> failwith "make_links"
        end

let decode spec dir =
  match spec with
      Auto -> dir
    | Dir d -> d

let rec make_labels dir =
  function
      Tile (spec, inst, reg, t) ->
        make_labels dir t;
        begin match t with
            Node (n, _, _) ->
              if inst <> "" then
                printf "inst.$($)(btex \\inst{$} etex);\n" 
                  [fStr (decode spec dir); fNum n; fStr inst];
              if reg <> "" then
                printf "reg.$($)(btex \\reg{$} etex);\n" 
                  [fStr dir; fNum n; fStr reg]
          | _ -> ()
        end
    | Untile t ->
        make_labels dir t
    | Node (_, _, []) -> ()
    | Node (_, _, [t]) -> make_labels dir t
    | Node (_, _, [t1; t2]) -> make_labels "lft" t1; make_labels "rt" t2
    | _ -> failwith "make_labels"   

let rec trace n =
  function
    | [Node (k, _, kids)] ->
        printf "..lseg($)" [fNum k];
        trace k kids;
        printf "..rseg($)" [fNum k]
    | [Node (k1, _, kids1); Node (k2, _, kids2)] ->
        printf "..lseg($)" [fNum k1];
        trace k1 kids1;
        printf "..fillet($,$)" [fNum k1; fNum k2];
        trace k2 kids2;
        printf "..rseg($)" [fNum k2]
    | [Node (k1, _, kids1); _] ->
        printf "..lseg($)" [fNum k1];
        trace k1 kids1;
        printf "..rseg($)" [fNum k1]
    | [_; Node (k2, _, kids2)] ->
        printf "..lseg($)" [fNum k2];
        trace k2 kids2;
        printf "..rseg($)" [fNum k2]
    | [] | [_] | [_; _] -> printf " ..bseg($)" [fNum n]
    | _ -> failwith "trace"

let rainbow = ref 0

let colour () =
  let n = !rainbow in incr rainbow; n

let cflag = ref false

let rec make_tiles =
  function
      Tile (spec, inst, reg, t) ->
        make_tiles t;
        begin match t with
            Node (n, _, kids) ->
              if !cflag then printf "shade($) " [fNum (colour ())]
              else printf "draw " [];
              printf "tseg($)" [fNum n];
              trace n kids;
              printf "..cycle;\n" []
          | _ -> ()
        end
    | Untile t ->
        make_tiles t
    | Node (_, _, kids) ->
        List.iter make_tiles kids

let spec =
  Arg.align [
    "-c", Arg.Set cflag, " Colour the ovals"]

let main () =
  let fname = ref "-" in
  Arg.parse spec (function s -> fname := s) "Usage:";
  let chan = 
    if !fname = "-" then
      stdin
    else begin
      Oplex.fname := !fname;
      open_in !Oplex.fname
    end in
  let lexbuf = Lexing.from_channel chan in
  let tree =
    try Opgram.tree Oplex.token lexbuf with
      Parsing.Parse_error ->
        let tok = Lexing.lexeme lexbuf in
	fprintf stderr "\"$\", line $: syntax error at token '$'\n" 
	  [fStr !Oplex.fname; fNum !Oplex.lnum; fStr tok];
	exit 1 in

  printf "input opdraw.mp\n" [];
  printf "verbatimtex \\input opdraw.tex etex\n" [];
  printf "begintree(1);\n" [];

  let _ = layout tree in
  make_nodes 5.0 5.0 tree;
  make_links 0 'x' tree;
  make_tiles tree;
  printf "drawtree($);\n" [fNum !Optree.nnodes];
  make_labels "lft" tree;

  printf "endfig;\n" [];
  printf "end\n" []

let opdraw = main ()
