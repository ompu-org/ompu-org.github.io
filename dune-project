(lang dune 3.0)

(name jsoo-alhbed)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Yoshihiro Imai")

(maintainers "Yoshihiro Imai")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name jsoo-alhbed)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends ocaml dune js_of_ocaml-ppx uutf)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
