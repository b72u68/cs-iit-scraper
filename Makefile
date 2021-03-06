SRC_DIR := src
PROJECT_NAME := cs-iit-scraper

all: $(SRC_DIR)/$(PROJECT_NAME).ml
	ocamlbuild -I src -use-ocamlfind $(PROJECT_NAME).native

build: $(SRC_DIR)/$(PROJECT_NAME).ml
	ocamlbuild -I src -use-ocamlfind $(PROJECT_NAME).native

run: $(PROJECT_NAME).native
	./$(PROJECT_NAME).native

clean:
	ocamlbuild -clean
