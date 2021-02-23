%{
open Optree
open Print

let add_tag base tag =
  sprintf "$^{[$]}" [fStr base; fStr tag]
%}

%token <string> OPEN IDENT TAG
%token <Optree.spec> TILE
%token CLOSE COMMA
%token UNTILE
%token BADTOK EOF

%type<Optree.tree> tree

%start tree

%%

tree :
    TILE IDENT IDENT tree { Tile ($1, $2, $3, $4) }
  | TILE IDENT tree { Tile ($1, $2, "", $3) }
  | TILE tree { Tile ($1, "", "", $2) }
  | UNTILE tree { Untile $2 }
  | opening nodenum args CLOSE { Node ($2, $1, $3) } ;

opening : OPEN { $1 }
  | OPEN TAG { add_tag $1 $2 } ;

nodenum :
    /* empty */ { incr nnodes; !nnodes }

args :
    /* empty */ { [] }
  | COMMA tree args { $2 :: $3 } ;

