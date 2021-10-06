# CS at IIT Scraper
Ocaml web scraper for Computer Science courses on Illinois Tech website
using [Cohttp](https://github.com/mirage/ocaml-cohttp), 
[Lwt](https://ocsigen.org/lwt/latest/manual/manual), 
and [Lambdasoup](https://github.com/aantron/lambdasoup).

## Installation

This project requires Ocaml and Ocaml package manager `opam`. To install
`opam`, use the command line bellow in your preferred shell or follow 
this link [Install OPAM](https://opam.ocaml.org/doc/Install.html).

```bash
your-package-manager install opam
opam init
```

Clone this repository to your local machine and install the requirement
libraries using `opam`.

```bash
git clone https://github.com/b72u68/cs-iit-scraper
cd cs-iit-scraper
opam install .
```

## Build

Run the following command to build project and create executable file.

```bash
make
```

or you can do

```bash
make build 
```

or 

```bash
ocamlbuild -I src -use-ocamlfind scraper.native
```
