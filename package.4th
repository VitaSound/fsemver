\ Follows theforth.net publishing guidelines:
\   https://theforth.net/guidelines
\ Order: mandatory meta keys first (name, version, license, main),
\ optional metadata (description, tags), dependencies last.
forth-package
    key-value name fsemver
    key-value version 0.1.0
    key-value description Semver requirement parser and matcher (Hex/Elixir-style ~> plus >= == > < <=) for Forth tooling
    key-value license COPL
    key-value main fsemver.4th
    key-list tags semver
    key-list tags version-requirement
    key-list tags pinning
    key-list tags gforth
    key-list dependencies ttester git https://github.com/VitaSound/ttester tag 1.2.0
end-forth-package
