# opdraw/Makefile
# Copyright (c) 2021 J. M. Spivey

all: opdraw mp2pdf

## opdraw

opdraw: print.cmo optree.cmo oplex.cmo opgram.cmo opmain.cmo
	ocamlc -o $@ $^

opgram.ml opgram.mli: opgram.mly
	ocamlyacc opgram.mly

oplex.ml: oplex.mll
	ocamllex oplex.mll

## mp2pdf

mp2pdf: mp2parse.o mp2scan.o
	gcc -g -o $@ $^

mp2parse.c mp2parse.h: mp2parse.y
	bison -d -o mp2parse.c $<

mp2scan.c: mp2scan.l
	flex -o $@ $< 

mp2scan.o mp2parse.o: mp2parse.h


%.cmi: %.mli
	ocamlc -c -g $<

%.cmo: %.ml
	ocamlc -c -g $<

clean: force
	rm -f opdraw *.cmi *.cmo oplex.ml opgram.mli opgram.ml
	rm -f mp2pdf *.o mp2parse.c mp2parse.h mp2scan.c
	rm -f *.pdf *.1 *.log *.mpx *.mtx *.png sample.tex sample.mp

force:

CC = gcc
CFLAGS = -g

##

oplex.cmo : opgram.cmi
opgram.cmi : optree.cmo
opgram.cmo : opgram.cmi optree.cmo
print.cmo : print.cmi
opmain.cmo : oplex.cmi opgram.cmi

