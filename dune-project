(lang dune 3.8)
(name cn_agent)

; MDX for executable documentation
(using mdx 0.4)

; Package metadata
(generate_opam_files true)

(package
 (name cn_agent)
 (allow_empty)
 (synopsis "CLI and tools for cn-agent hubs")
 (description "Coherence Network agent infrastructure: native OCaml CLI")
 (license Apache-2.0)
 (authors "Sigma <sigma@usurobor.dev>" "Pi <pi@usurobor.dev>")
 (maintainers "usurobor@gmail.com")
 (homepage "https://github.com/usurobor/cnos")
 (source (github usurobor/cnos))
 (bug_reports "https://github.com/usurobor/cnos/issues")
 (depends
  (ocaml (>= 4.14))
  (dune (>= 3.0))))
