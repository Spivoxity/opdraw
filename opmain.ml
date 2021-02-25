(* opmain.ml *)
(* Copyright (c) 2021 J. M. Spivey *)

open Print
open Optree

let delta = Hashtbl.create 100

let rec set_delta n d = Hashtbl.add delta n d

(* |find_gap| -- determine smallest gap to avoid overlap *)
let rec find_gap p1 p2 =
  match (p1, p2) with
      ([], _) -> 0.0
    | (_, []) -> 0.0
    | ((_, y1) :: q1, (x2, _) :: q2) ->
        max (y1 +. x2 +. 1.0) (find_gap q1 q2)

(* |shift| -- shift a profile to left or right *)
let rec shift d = List.map (fun (x, y) -> (x-.d, y+.d))

(* |join| -- join two profiles side by side *)
let rec join p1 p2 =
  match (p1, p2) with
      ([], _) -> p2
    | (_, []) -> p1
    | ((x1, _) :: q1, (_, y2) :: q2) ->
        (x1, y2) :: join q1 q2

let maximum xs = List.fold_left max 0.0 xs

let rec take n =
  function
      [] -> []
    | x::xs -> if n = 0 then [] else x :: take (n-1) xs

(* |layout| -- lay out a tree and return its profile *)
let rec layout =
  function
      Tile (spec, inst, reg, t) -> layout t
    | Untile t -> layout t
    | Node (n, op, []) -> [(0.0, 0.0)]
    | Node (n, op, [t]) -> (0.0, 0.0) :: layout t
    | Node (n, op, ts) ->
        let nchn = List.length ts in
        let ps = List.map layout ts in
        let d = maximum (List.map2 find_gap (take (nchn-1) ps) (List.tl ps)) in
        set_delta n d;
        let x0 = -. (float_of_int (nchn-1) *. d /. 2.0) in
        let res = ref [] in
        for i = 0 to nchn-1 do
          res := join !res (shift (x0 +. float_of_int i *. d) (List.nth ps i))
        done;
        (0.0, 0.0) :: !res

(* |make_nodes| -- generate the nodes of a tree *)
let rec make_nodes x y =
  function
      Tile (spec, inst, reg, t) -> 
        make_nodes x y t
    | Untile t -> 
        make_nodes x y t
    | Node (n, op, kids) ->
        printf "node$($,$)(btex \\node{$} etex);\n" 
          [fNum n; fFlo x; fFlo y; fStr op];
        begin match kids with
            [] -> ()
          | [t] -> make_nodes x (y -. 1.0) t
          | ts ->
              let nchn = List.length ts in
              let dx = Hashtbl.find delta n in
              let x0 = x -. (float_of_int (nchn-1) *. dx /. 2.0) in
              for i = 0 to nchn-1 do
                make_nodes (x0 +. float_of_int i *. dx) (y -. 1.0)
                  (List.nth ts i)
              done
        end

(* |make_links| -- generate links between nodes *)
let rec make_links parent dir =
  function
      Tile (spec, inst, reg, t) ->
        make_links parent dir t
    | Untile t ->
        make_links parent dir t
    | Node (n, _, kids) ->
        if dir <> 'x' then 
          printf "link.$($,$);\n" [fChr dir; fNum parent; fNum n];
        begin match kids with
            [] -> ()
          | [t] -> make_links n 'v' t
          | ts ->
              let nchn = List.length ts in
              List.iter (make_links n 'l') (take (nchn-1) ts);
              make_links n 'r' (List.nth ts (nchn-1))
        end

(* |decode| -- interpret specification for label placement *)
let decode spec dir =
  match spec with
      Auto -> dir
    | Dir d -> d

(* |make_labels| -- generate tile and link labels *)
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
    | Untile t -> make_labels dir t
    | Node (_, _, []) -> ()
    | Node (_, _, [t]) -> make_labels dir t
    | Node (_, _, ts) ->
        let nchn = List.length ts in
        List.iter (make_labels "lft") (take (nchn-1) ts);
        make_labels "rt" (List.nth ts (nchn-1))

(* |trace| -- trace round subtrees that are part of a tile *)
let rec trace n =
  function
      [] ->
        (* No subtrees in the tile: draw the bottom of the parent *)
        printf "..bseg($)" [fNum n]
    | Node (k, _, kids) :: ts ->
        (* Found first subtree: trace it, then look for another *)
        printf "..lseg($)" [fNum k];
        trace k kids;
        trace1 n k true ts
    | _ :: ts ->
        (* A different tile: skip it *)
        trace n ts

(* |trace1| -- trace round subtrees in a tile after the first *)
and trace1 n j adj =
  function
      [] ->
        (* No more subtrees: finish off the most recent one *)
        printf "..rseg($)" [fNum j]
    | Node (k, _, kids) :: ts ->
        (* Another subtree: join with a fillet or leapfrog *)
        if adj then
          printf "..fillet($,$)" [fNum j; fNum k]
        else
          printf "..leapfrog($,$,$)" [fNum n; fNum j; fNum k];
        trace k kids;
        trace1 n k true ts
    | _ :: ts ->
        (* A different tile: skip and use a leapfrog for the next *)
        trace1 n j false ts

let rainbow = ref 0

let colour () =
  let n = !rainbow in incr rainbow; n

let cflag = ref false

(* |make_tiles| -- generate outlines for the tiles *)
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
  Arg.align ["-c", Arg.Set cflag, " Colour the ovals"]

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
  let (tree, nnodes) =
    try Opgram.file Oplex.token lexbuf with
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
  printf "pickup pencircle scaled outline;\n" [];
  make_tiles tree;
  printf "drawtree($);\n" [fNum nnodes];
  make_labels "lft" tree;

  printf "endfig;\n" [];
  printf "end\n" []

let opdraw = main ()
