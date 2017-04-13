/// Module for encapsulating helper functions for the Language model.

import R from "ramda";

import { isNullOrUndefined, filterWords, maybeMap } from "../util";


/**
 * All the supported languages, these match to the type-union on the frontend. We use language `name`s as their unique
 * key, and we use `humanReadableName` to improve search.
 *
 * @NOTE: Keep up to date with `frontend/src/Elements/Editor.elm`
 */
export const languages = [
  { name: "ActionScript", humanReadableName: "ActionScript" },
  { name: "Ada", humanReadableName: "Ada" },
  { name: "AppleScript", humanReadableName: "AppleScript" },
  { name: "AssemblyX86", humanReadableName: "Assembly_X86" },
  { name: "C", humanReadableName: "C" },
  { name: "CPlusPlus", humanReadableName: "C++" },
  { name: "Clojure", humanReadableName: "Clojure" },
  { name: "Cobol", humanReadableName: "Cobol" },
  { name: "CoffeeScript", humanReadableName: "CoffeeScript" },
  { name: "CSharp", humanReadableName: "C#" },
  { name: "CSS", humanReadableName: "CSS" },
  { name: "D", humanReadableName: "D" },
  { name: "Dart", humanReadableName: "Dart" },
  { name: "DockerFile", humanReadableName: "Dockerfile" },
  { name: "Elixir", humanReadableName: "Elixir" },
  { name: "Elm", humanReadableName: "Elm" },
  { name: "Erlang", humanReadableName: "Erlang" },
  { name: "Fortran", humanReadableName: "Fortran" },
  { name: "GoLang", humanReadableName: "Go" },
  { name: "Groovy", humanReadableName: "Groovy" },
  { name: "HAML", humanReadableName: "HAML" },
  { name: "HTML", humanReadableName: "HTML" },
  { name: "Haskell", humanReadableName: "Haskell" },
  { name: "Java", humanReadableName: "Java" },
  { name: "JavaScript", humanReadableName: "JavaScript" },
  { name: "JSON", humanReadableName: "JSON" },
  { name: "Latex", humanReadableName: "Latex" },
  { name: "Less", humanReadableName: "Less" },
  { name: "LiveScript", humanReadableName: "LiveScript" },
  { name: "Lua", humanReadableName: "Lua" },
  { name: "Makefile", humanReadableName: "Makefile" },
  { name: "Matlab", humanReadableName: "Matlab" },
  { name: "MySQL", humanReadableName: "MySQL" },
  { name: "ObjectiveC", humanReadableName: "ObjectiveC" },
  { name: "OCaml", humanReadableName: "OCaml" },
  { name: "Pascal", humanReadableName: "Pascal" },
  { name: "Perl", humanReadableName: "Perl" },
  { name: "PGSQL", humanReadableName: "PGSQL" },
  { name: "PHP", humanReadableName: "PHP" },
  { name: "PowerShell", humanReadableName: "PowerShell" },
  { name: "Prolog", humanReadableName: "Prolog" },
  { name: "Python", humanReadableName: "Python" },
  { name: "R", humanReadableName: "R" },
  { name: "Ruby", humanReadableName: "Ruby" },
  { name: "Rust", humanReadableName: "Rust" },
  { name: "SASS", humanReadableName: "SASS" },
  { name: "Scala", humanReadableName: "Scala" },
  { name: "SQL", humanReadableName: "SQL" },
  { name: "SQLServer", humanReadableName: "SQLServer" },
  { name: "Swift", humanReadableName: "Swift" },
  { name: "TypeScript", humanReadableName: "TypeScript" },
  { name: "XML", humanReadableName: "XML" },
  { name: "YAML", humanReadableName: "YAML" },
];

/**
 * Returns true if `languageName` is exactly a valid language name.
 */
export const isLanguage = (languageName: string): boolean => {
  return R.contains(languageName, R.map(R.prop("name"))(languages));
};

/**
 * Removes all languages from the sentence, uses `languageFromWord` to do word matching.
 */
export const stripLanguagesFromWords = (sentence: string): string => {
  return filterWords(sentence, R.pipe(languageFromWord, isNullOrUndefined));
}

/**
 * Get's all the languages mentioned in the sentence, uses `languageFromWord` to do word matching.
 */
export const languagesFromWords = maybeMap((sentenceInput: string): string[] => {
  return R.pipe(
    R.split(" "),
    R.map(languageFromWord),
    R.filter<string>(x => !isNullOrUndefined(x)),
    R.uniq
  )(sentenceInput);
});

/**
 * Get's the language from [user] input, returns `null` if no match. Allows matching against either the regular name or
 * the humanReadableName (and ignores case) but requires the full name, so 'El' will not match 'Elm'.
 */
export const languageFromWord = maybeMap((languageNameInput: string): string => {

  const languageNameInputLowercase = languageNameInput.toLowerCase();

  for(let { name, humanReadableName } of languages) {
    if(name.toLowerCase() === languageNameInputLowercase
        || humanReadableName.toLowerCase() === languageNameInputLowercase ) {
      return name;
    }
  }

  return null;
});
