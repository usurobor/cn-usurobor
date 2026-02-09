(lang dune 3.8)
(name cn_agent)

; Melange for OCaml → JavaScript compilation
(using melange 0.1)

; MDX for executable documentation
(using mdx 0.4)

; Package metadata
(generate_opam_files true)

(package
 (name cn_agent)
 (allow_empty)
 (synopsis "CLI and tools for cn-agent hubs")
 (description "Coherence Network agent infrastructure: CLI setup, peer-sync, validation tools")
 (license Apache-2.0)
 (authors "Sigma <sigma@usurobor.dev>" "Pi <pi@usurobor.dev>")
 (maintainers "usurobor@gmail.com")
 (homepage "https://github.com/usurobor/cn-agent")
 (source (github usurobor/cn-agent))
 (bug_reports "https://github.com/usurobor/cn-agent/issues")
 (depends
  (ocaml (>= 4.14))
  (dune (>= 3.0))
  (melange (>= 3.0))))
