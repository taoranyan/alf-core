
Clip input tuples to a subset of attributes

SYNOPSIS

  #{shell_signature}

OPTIONS
#{summarized_options}

DESCRIPTION

This operator clips tuples on attributes whose names are specified in 
ATTR_LIST. This is similar to the relational PROJECT operator, expect
that CLIP does not remove duplicates afterwards.

Clipping may therefore lead to bags of tuples instead of sets. The result
is **not** a valid relation unless a candidate key is preserved.

With --allbut, the operator keeps attributes in ATTR_LIST, instead of 
projecting them away. 

EXAMPLE

  alf clip suppliers -- name city
  alf clip suppliers --allbut -- name city
