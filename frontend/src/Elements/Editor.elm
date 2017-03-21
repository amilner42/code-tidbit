module Elements.Editor exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div)
import Html.Attributes exposing (class, id)


-- TODO Dup code here is driving me crazy, some is needed but some can be
-- definitely be removed. Not a priority.


{-| The languages the Ace Editor supports.
-}
type Language
    = ActionScript
    | Ada
    | AppleScript
    | AssemblyX86
    | C
    | CPlusPlus
    | Clojure
    | Cobol
    | CoffeeScript
    | CSharp
    | CSS
    | D
    | Dart
    | DockerFile
    | Elixir
    | Elm
    | Erlang
    | Fortran
    | GoLang
    | Groovy
    | HAML
    | HTML
    | Haskell
    | Java
    | JavaScript
    | JSON
    | Latex
    | Less
    | LiveScript
    | Lua
    | Makefile
    | Matlab
    | MySQL
    | ObjectiveC
    | OCaml
    | Pascal
    | Perl
    | PGSQL
    | PHP
    | PowerShell
    | Prolog
    | Python
    | R
    | Ruby
    | Rust
    | SASS
    | Scala
    | SQL
    | SQLServer
    | Swift
    | TypeScript
    | XML
    | YAML


{-| Themes supported by the ACE editor.
-}
type Theme
    = Chaos
    | Chrome
    | CloudsMidnight
    | Clouds
    | Cobalt
    | CrimsonEditor
    | Dawn
    | Dreamweaver
    | Eclipse
    | Github
    | IdleFingers
    | IPlastic
    | Kuroir
    | MerbivoreSoft
    | Monokai
    | PastelOnDark
    | SolarizedDark
    | SolarizedLight
    | Tomorrow
    | Twilight
    | XCode


{-| Get's the human readable name.
-}
getHumanReadableName : Language -> String
getHumanReadableName language =
    case language of
        ActionScript ->
            "ActionScript"

        Ada ->
            "Ada"

        AppleScript ->
            "AppleScript"

        AssemblyX86 ->
            "Assembly_X86"

        C ->
            "C"

        CPlusPlus ->
            "C++"

        Clojure ->
            "Clojure"

        Cobol ->
            "Cobol"

        CoffeeScript ->
            "CoffeeScript"

        CSharp ->
            "C#"

        CSS ->
            "CSS"

        D ->
            "D"

        Dart ->
            "Dart"

        DockerFile ->
            "Dockerfile"

        Elixir ->
            "Elixir"

        Elm ->
            "Elm"

        Erlang ->
            "Erlang"

        Fortran ->
            "Fortran"

        GoLang ->
            "Go"

        Groovy ->
            "Groovy"

        HAML ->
            "HAML"

        HTML ->
            "HTML"

        Haskell ->
            "Haskell"

        Java ->
            "Java"

        JavaScript ->
            "JavaScript"

        JSON ->
            "JSON"

        Latex ->
            "Latex"

        Less ->
            "Less"

        LiveScript ->
            "LiveScript"

        Lua ->
            "Lua"

        Makefile ->
            "Makefile"

        Matlab ->
            "Matlab"

        MySQL ->
            "MySQL"

        ObjectiveC ->
            "ObjectiveC"

        OCaml ->
            "OCaml"

        Pascal ->
            "Pascal"

        Perl ->
            "Perl"

        PGSQL ->
            "PGSQL"

        PHP ->
            "PHP"

        PowerShell ->
            "PowerShell"

        Prolog ->
            "Prolog"

        Python ->
            "Python"

        R ->
            "R"

        Ruby ->
            "Ruby"

        Rust ->
            "Rust"

        SASS ->
            "SASS"

        Scala ->
            "Scala"

        SQL ->
            "SQL"

        SQLServer ->
            "SQLServer"

        Swift ->
            "Swift"

        TypeScript ->
            "TypeScript"

        XML ->
            "XML"

        YAML ->
            "YAML"


{-| Human readable list of langauges, we need this list for searching purposes.
-}
humanReadableListOfLanguages : List ( Language, String )
humanReadableListOfLanguages =
    [ ( ActionScript, "ActionScript" )
    , ( Ada, "Ada" )
    , ( AppleScript, "AppleScript" )
    , ( AssemblyX86, "Assembly_X86" )
    , ( C, "C" )
    , ( CPlusPlus, "C++" )
    , ( Clojure, "Clojure" )
    , ( Cobol, "Cobol" )
    , ( CoffeeScript, "CoffeeScript" )
    , ( CSharp, "C#" )
    , ( CSS, "CSS" )
    , ( D, "D" )
    , ( Dart, "Dart" )
    , ( DockerFile, "Dockerfile" )
    , ( Elixir, "Elixir" )
    , ( Elm, "Elm" )
    , ( Erlang, "Erlang" )
    , ( Fortran, "Fortran" )
    , ( GoLang, "Go" )
    , ( Groovy, "Groovy" )
    , ( HAML, "HAML" )
    , ( HTML, "HTML" )
    , ( Haskell, "Haskell" )
    , ( Java, "Java" )
    , ( JavaScript, "JavaScript" )
    , ( JSON, "JSON" )
    , ( Latex, "Latex" )
    , ( Less, "Less" )
    , ( LiveScript, "LiveScript" )
    , ( Lua, "Lua" )
    , ( Makefile, "Makefile" )
    , ( Matlab, "Matlab" )
    , ( MySQL, "MySQL" )
    , ( ObjectiveC, "ObjectiveC" )
    , ( OCaml, "OCaml" )
    , ( Pascal, "Pascal" )
    , ( Perl, "Perl" )
    , ( PGSQL, "PGSQL" )
    , ( PHP, "PHP" )
    , ( PowerShell, "PowerShell" )
    , ( Prolog, "Prolog" )
    , ( Python, "Python" )
    , ( R, "R" )
    , ( Ruby, "Ruby" )
    , ( Rust, "Rust" )
    , ( SASS, "SASS" )
    , ( Scala, "Scala" )
    , ( SQL, "SQL" )
    , ( SQLServer, "SQLServer" )
    , ( Swift, "Swift" )
    , ( TypeScript, "TypeScript" )
    , ( XML, "XML" )
    , ( YAML, "YAML" )
    ]


{-| Given a file name, like `bla.py`, returns the appropriate language [python].

NOTE: Due to ambiguity in certain file extensions (.sql), we return a list of
the possible languages it could be. An empty list means it's an unsupported file
extension.

NOTE: This is the fileName, not the absolute path.
-}
languagesFromFileName : String -> List Language
languagesFromFileName fileName =
    let
        maybeSuffix =
            ((String.split ".") >> Util.lastElem) fileName
    in
        -- Fucking docker...
        if fileName == "Dockerfile" then
            [ DockerFile ]
        else if not <| String.contains "." fileName then
            []
        else
            case maybeSuffix of
                Nothing ->
                    []

                Just suffix ->
                    case suffix of
                        "as" ->
                            [ ActionScript ]

                        "a" ->
                            [ Ada ]

                        "scpt" ->
                            [ AppleScript ]

                        "asm" ->
                            [ AssemblyX86 ]

                        "c" ->
                            [ C ]

                        "cc" ->
                            [ CPlusPlus ]

                        "cpp" ->
                            [ CPlusPlus ]

                        "h" ->
                            [ CPlusPlus ]

                        "clj" ->
                            [ Clojure ]

                        "cljs" ->
                            [ Clojure ]

                        "cljc" ->
                            [ Clojure ]

                        "edn" ->
                            [ Clojure ]

                        "cbl" ->
                            [ Cobol ]

                        "cob" ->
                            [ Cobol ]

                        "coffee" ->
                            [ CoffeeScript ]

                        "cs" ->
                            [ CSharp ]

                        "css" ->
                            [ CSS ]

                        "d" ->
                            [ D ]

                        "dart" ->
                            [ Dart ]

                        "ex" ->
                            [ Elixir ]

                        "exs" ->
                            [ Elixir ]

                        "elm" ->
                            [ Elm ]

                        "erl" ->
                            [ Erlang ]

                        "hrl" ->
                            [ Erlang ]

                        "f" ->
                            [ Fortran ]

                        "for" ->
                            [ Fortran ]

                        "go" ->
                            [ GoLang ]

                        "groovy" ->
                            [ Groovy ]

                        "haml" ->
                            [ HAML ]

                        "html" ->
                            [ HTML ]

                        "hs" ->
                            [ Haskell ]

                        "java" ->
                            [ Java ]

                        "js" ->
                            [ JavaScript ]

                        "json" ->
                            [ JSON ]

                        "dtx" ->
                            [ Latex ]

                        "lpx" ->
                            [ Latex ]

                        "less" ->
                            [ Less ]

                        "ls" ->
                            [ LiveScript ]

                        "lua" ->
                            [ Lua ]

                        "mak" ->
                            [ Makefile ]

                        "matlab" ->
                            [ Matlab ]

                        "sql" ->
                            [ MySQL, PGSQL, SQL, SQLServer ]

                        "m" ->
                            [ ObjectiveC ]

                        "ml" ->
                            [ OCaml ]

                        "mli" ->
                            [ OCaml ]

                        "pas" ->
                            [ Pascal ]

                        "pascal" ->
                            [ Pascal ]

                        "pl" ->
                            [ Perl ]

                        "php" ->
                            [ PHP ]

                        "ps1" ->
                            [ PowerShell ]

                        "pro" ->
                            [ Prolog ]

                        "py" ->
                            [ Python ]

                        "r" ->
                            [ R ]

                        "rb" ->
                            [ Ruby ]

                        "rs" ->
                            [ Rust ]

                        "scss" ->
                            [ SASS ]

                        "sass" ->
                            [ SASS ]

                        "scala" ->
                            [ Scala ]

                        "sc" ->
                            [ Scala ]

                        "swift" ->
                            [ Swift ]

                        "ts" ->
                            [ TypeScript ]

                        "xml" ->
                            [ XML ]

                        "yaml" ->
                            [ YAML ]

                        _ ->
                            []


{-| Given a language, returns the ACE location which can be used with the ACE
API to set the language.
-}
aceLanguageLocation : Language -> String
aceLanguageLocation lang =
    let
        baseLocation =
            "ace/mode/"

        languagePath =
            case lang of
                ActionScript ->
                    "actionscript"

                Ada ->
                    "ada"

                AppleScript ->
                    "applescript"

                AssemblyX86 ->
                    "assembly_x86"

                C ->
                    "c_cpp"

                CPlusPlus ->
                    "c_cpp"

                Clojure ->
                    "clojure"

                Cobol ->
                    "cobol"

                CoffeeScript ->
                    "coffee"

                CSharp ->
                    "csharp"

                CSS ->
                    "css"

                D ->
                    "d"

                Dart ->
                    "dart"

                DockerFile ->
                    "dockerfile"

                Elixir ->
                    "elixir"

                Elm ->
                    "elm"

                Erlang ->
                    "erlang"

                Fortran ->
                    "fortran"

                GoLang ->
                    "golang"

                Groovy ->
                    "groovy"

                HAML ->
                    "haml"

                Haskell ->
                    "haskell"

                HTML ->
                    "html"

                Java ->
                    "java"

                JavaScript ->
                    "javascript"

                JSON ->
                    "json"

                Latex ->
                    "latex"

                Less ->
                    "less"

                LiveScript ->
                    "livescript"

                Lua ->
                    "lua"

                Makefile ->
                    "makefile"

                Matlab ->
                    "matlab"

                MySQL ->
                    "mysql"

                ObjectiveC ->
                    "objectivec"

                OCaml ->
                    "ocaml"

                Pascal ->
                    "pascal"

                Perl ->
                    "perl"

                PGSQL ->
                    "pgsql"

                PHP ->
                    "php"

                PowerShell ->
                    "powershell"

                Prolog ->
                    "prolog"

                Python ->
                    "python"

                R ->
                    "r"

                Ruby ->
                    "ruby"

                Rust ->
                    "rust"

                SASS ->
                    "sass"

                Scala ->
                    "scala"

                SQL ->
                    "sql"

                SQLServer ->
                    "sqlserver"

                Swift ->
                    "swift"

                TypeScript ->
                    "typescript"

                XML ->
                    "xml"

                YAML ->
                    "yaml"
    in
        baseLocation ++ languagePath


{-| Given a theme, returns the location which can be used with the ACE API to
set the theme.
-}
aceThemeLocation : Theme -> String
aceThemeLocation theme =
    let
        baseLocation =
            "ace/theme/"

        themeLocation =
            case theme of
                Chaos ->
                    "chaos"

                Chrome ->
                    "chrome"

                CloudsMidnight ->
                    "clouds_midnight"

                Clouds ->
                    "clouds"

                Cobalt ->
                    "cobalt"

                CrimsonEditor ->
                    "crimson_editor"

                Dawn ->
                    "dawn"

                Dreamweaver ->
                    "dreamweaver"

                Eclipse ->
                    "eclipse"

                Github ->
                    "github"

                IdleFingers ->
                    "idle_fingers"

                IPlastic ->
                    "iplastic"

                Kuroir ->
                    "kuroir"

                MerbivoreSoft ->
                    "merbivore_soft"

                Monokai ->
                    "monokai"

                PastelOnDark ->
                    "pastel_on_dark"

                SolarizedDark ->
                    "solarized_dark"

                SolarizedLight ->
                    "solarized_light"

                Tomorrow ->
                    "tomorrow"

                Twilight ->
                    "twilight"

                XCode ->
                    "xcode"
    in
        baseLocation ++ themeLocation


{-| Use this to create a code editor with id `editorID`.

NOTE: You should only ever have one editor at a time.
-}
editor : String -> Html msg
editor editorID =
    div
        [ id "code-editor-wrapper"
        ]
        [ Util.keyedDiv
            [ id editorID ]
            []
        ]
