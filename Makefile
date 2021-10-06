all: scraper.ml
	ocamlbuild -use-ocamlfind scraper.native
	./scraper.native

build: scraper.ml
	ocamlbuild -use-ocamlfind scraper.native

run: scrapper.native
	./scraper.native

clean:
	ocamlbuild -clean
