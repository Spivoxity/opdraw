type spec = Auto | Dir of string

type tree = 
    Tile of spec * string * string * tree
  | Untile of tree
  | Node of int * string * tree list     

let nnodes = ref 0
