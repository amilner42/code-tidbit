module Elements.Editor
    exposing
        ( aceLanguageLocation
        , aceThemeLocation
        , editor
        , humanReadableListOfLanguages
        , Language(..)
        , languageCacheDecoder
        , languageCacheEncoder
        , Theme(..)
        )

import Html exposing (Html, div)
import Html.Attributes exposing (class, id)
import Html.Keyed as Keyed
import Json.Encode as Encode
import Json.Decode as Decode


{-| The languages the Ace Editor supports.
-}
type Language
    = ActionScript
    | Ada
    | AppleScript
    | AssemblyX86
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
    | Haml
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
    | Sass
    | SQL
    | SQLServer
    | Swift
    | TypeScript
    | XML


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


{-| Human readable list of langauges.
-}
humanReadableListOfLanguages : List ( Language, String )
humanReadableListOfLanguages =
    [ ( ActionScript, "actionscript" )
    , ( Ada, "ada" )
    , ( AppleScript, "applescript" )
    , ( AssemblyX86, "assembly_x86" )
    , ( CPlusPlus, "c++" )
    , ( Clojure, "clojure" )
    , ( Cobol, "cobol" )
    , ( CoffeeScript, "coffeescript" )
    , ( CSharp, "c#" )
    , ( CSS, "css" )
    , ( D, "d" )
    , ( Dart, "dart" )
    , ( DockerFile, "dockerfile" )
    , ( Elixir, "elixir" )
    , ( Elm, "elm" )
    , ( Erlang, "erlang" )
    , ( Fortran, "fortran" )
    , ( GoLang, "go" )
    , ( Groovy, "groovy" )
    , ( Haml, "haml" )
    , ( Haskell, "haskell" )
    , ( Java, "java" )
    , ( JavaScript, "javascript" )
    , ( JSON, "json" )
    , ( Latex, "latex" )
    , ( Less, "less" )
    , ( LiveScript, "livescript" )
    , ( Lua, "lua" )
    , ( Makefile, "makefile" )
    , ( Matlab, "matlab" )
    , ( MySQL, "mysql" )
    , ( ObjectiveC, "objectivec" )
    , ( OCaml, "ocaml" )
    , ( Pascal, "pascal" )
    , ( Perl, "perl" )
    , ( PGSQL, "pgsql" )
    , ( PHP, "php" )
    , ( PowerShell, "powershell" )
    , ( Prolog, "prolog" )
    , ( Python, "python" )
    , ( R, "r" )
    , ( Ruby, "ruby" )
    , ( Rust, "rust" )
    , ( Sass, "sass" )
    , ( SQL, "sql" )
    , ( SQLServer, "sqlserver" )
    , ( Swift, "swift" )
    , ( TypeScript, "typescript" )
    , ( XML, "xml" )
    ]


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

                Haml ->
                    "haml"

                Haskell ->
                    "haskell"

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

                Sass ->
                    "sass"

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
    in
        baseLocation ++ languagePath


{-| Language `cacheEncoder`.
-}
languageCacheEncoder : Language -> Encode.Value
languageCacheEncoder language =
    Encode.string (toString language)


{-| Language `cacheDecoder`.
-}
languageCacheDecoder : Decode.Decoder Language
languageCacheDecoder =
    let
        fromStringDecoder : String -> Decode.Decoder Language
        fromStringDecoder encodedLanguage =
            case encodedLanguage of
                "ActionScript" ->
                    Decode.succeed ActionScript

                "Ada" ->
                    Decode.succeed Ada

                "AppleScript" ->
                    Decode.succeed AppleScript

                "AssemblyX86" ->
                    Decode.succeed AssemblyX86

                "CPlusPlus" ->
                    Decode.succeed CPlusPlus

                "Clojure" ->
                    Decode.succeed Clojure

                "Cobol" ->
                    Decode.succeed Cobol

                "CoffeeScript" ->
                    Decode.succeed CoffeeScript

                "CSharp" ->
                    Decode.succeed CSharp

                "CSS" ->
                    Decode.succeed CSS

                "D" ->
                    Decode.succeed D

                "Dart" ->
                    Decode.succeed Dart

                "DockerFile" ->
                    Decode.succeed DockerFile

                "Elixir" ->
                    Decode.succeed Elixir

                "Elm" ->
                    Decode.succeed Elm

                "Erlang" ->
                    Decode.succeed Erlang

                "Fortran" ->
                    Decode.succeed Fortran

                "GoLang" ->
                    Decode.succeed GoLang

                "Groovy" ->
                    Decode.succeed Groovy

                "Haml" ->
                    Decode.succeed Haml

                "Haskell" ->
                    Decode.succeed Haskell

                "Java" ->
                    Decode.succeed Java

                "JavaScript" ->
                    Decode.succeed JavaScript

                "JSON" ->
                    Decode.succeed JSON

                "Latex" ->
                    Decode.succeed Latex

                "Less" ->
                    Decode.succeed Less

                "LiveScript" ->
                    Decode.succeed LiveScript

                "Lua" ->
                    Decode.succeed Lua

                "Makefile" ->
                    Decode.succeed Makefile

                "Matlab" ->
                    Decode.succeed Matlab

                "MySQL" ->
                    Decode.succeed MySQL

                "ObjectiveC" ->
                    Decode.succeed ObjectiveC

                "OCaml" ->
                    Decode.succeed OCaml

                "Pascal" ->
                    Decode.succeed Pascal

                "Perl" ->
                    Decode.succeed Perl

                "PGSQL" ->
                    Decode.succeed PGSQL

                "PHP" ->
                    Decode.succeed PHP

                "PowerShell" ->
                    Decode.succeed PowerShell

                "Prolog" ->
                    Decode.succeed Prolog

                "Python" ->
                    Decode.succeed Python

                "R" ->
                    Decode.succeed R

                "Ruby" ->
                    Decode.succeed Ruby

                "Rust" ->
                    Decode.succeed Rust

                "Sass" ->
                    Decode.succeed Sass

                "SQL" ->
                    Decode.succeed SQL

                "SQLServer" ->
                    Decode.succeed SQLServer

                "Swift" ->
                    Decode.succeed Swift

                "TypeScript" ->
                    Decode.succeed TypeScript

                "XML" ->
                    Decode.succeed XML

                _ ->
                    Decode.fail <| encodedLanguage ++ " is not a valid encoded string."
    in
        Decode.andThen fromStringDecoder Decode.string


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
        [ Keyed.node
            "div"
            [ id editorID ]
            []
        ]
