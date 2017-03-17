/// 1st migration file.

/**
 * All the supported languages.
 *
 * @refer `Language` in types.ts.
 */
const languages = [
  {
    encodedName: "ActionScript",
  },
  {
    encodedName: "Ada",
  },
  {
    encodedName: "AppleScript",
  },
  {
    encodedName: "AssemblyX86",
  },
  {
    encodedName: "C"
  },
  {
    encodedName: "CPlusPlus",
  },
  {
    encodedName: "Clojure",
  },
  {
    encodedName: "Cobol",
  },
  {
    encodedName: "CoffeeScript",
  },
  {
    encodedName: "CSharp",
  },
  {
    encodedName: "CSS",
  },
  {
    encodedName: "D",
  },
  {
    encodedName: "Dart",
  },
  {
    encodedName: "DockerFile",
  },
  {
    encodedName: "Elixir",
  },
  {
    encodedName: "Elm",
  },
  {
    encodedName: "Erlang",
  },
  {
    encodedName: "Fortran",
  },
  {
    encodedName: "GoLang",
  },
  {
    encodedName: "Groovy",
  },
  {
    encodedName: "HTML"
  },
  {
    encodedName: "HAML",
  },
  {
    encodedName: "Haskell",
  },
  {
    encodedName: "Java",
  },
  {
    encodedName: "JavaScript",
  },
  {
    encodedName: "JSON",
  },
  {
    encodedName: "Latex",
  },
  {
    encodedName: "Less",
  },
  {
    encodedName: "LiveScript",
  },
  {
    encodedName: "Lua",
  },
  {
    encodedName: "Makefile",
  },
  {
    encodedName: "Matlab",
  },
  {
    encodedName: "MySQL",
  },
  {
    encodedName: "ObjectiveC",
  },
  {
    encodedName: "OCaml",
  },
  {
    encodedName: "Pascal",
  },
  {
    encodedName: "Perl",
  },
  {
    encodedName: "PGSQL",
  },
  {
    encodedName: "PHP",
  },
  {
    encodedName: "PowerShell",
  },
  {
    encodedName: "Prolog",
  },
  {
    encodedName: "Python",
  },
  {
    encodedName: "R",
  },
  {
    encodedName: "Ruby",
  },
  {
    encodedName: "Rust",
  },
  {
    encodedName: "SASS",
  },
  {
    encodedName: "Scala"
  },
  {
    encodedName: "SQL",
  },
  {
    encodedName: "SQLServer",
  },
  {
    encodedName: "Swift",
  },
  {
    encodedName: "TypeScript",
  },
  {
    encodedName: "XML",
  },
  {
    encodedName: "YAML"
  }
];

db.languages.insert(languages);

// Initial Indexes

db.completed.createIndex({ user: 1, tidbitPointer: 1});
db.snipbits.createIndex({ author: 1 });
db.bigbits.createIndex({ author: 1 });
db.stories.createIndex({ author: 1 });
