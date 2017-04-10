/// Module for encapsulating helper functions for the Language model.

import R from "ramda";


/**
 * All the supported languages, these match to the type-union on the frontend for `Language`s.
 */
export const languages = [
  "ActionScript",
  "Ada",
  "AppleScript",
  "AssemblyX86",
  "C",
  "CPlusPlus",
  "Clojure",
  "Cobol",
  "CoffeeScript",
  "CSharp",
  "CSS",
  "D",
  "Dart",
  "DockerFile",
  "Elixir",
  "Elm",
  "Erlang",
  "Fortran",
  "GoLang",
  "Groovy",
  "HTML",
  "HAML",
  "Haskell",
  "Java",
  "JavaScript",
  "JSON",
  "Latex",
  "Less",
  "LiveScript",
  "Lua",
  "Makefile",
  "Matlab",
  "MySQL",
  "ObjectiveC",
  "OCaml",
  "Pascal",
  "Perl",
  "PGSQL",
  "PHP",
  "PowerShell",
  "Prolog",
  "Python",
  "R",
  "Ruby",
  "Rust",
  "SASS",
  "Scala",
  "SQL",
  "SQLServer",
  "Swift",
  "TypeScript",
  "XML",
  "YAML"
];

/**
 * Returns true if `language` is a valid language.
 */
export const isLanguage = (language: string): boolean => {
  return R.contains(language, languages);
}
