module Elements.Editor
    exposing
        ( aceLanguageLocation
        , aceThemeLocation
        , editor
        , Language(..)
        , Theme(..)
        )

import Html exposing (Html, div)
import Html.Attributes exposing (class, id)


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
                    "golong"

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


{-| The editor, has special classes attached for styling and a special ID
attached so that the js knows which div to replace with the ace-editor.

NOTE: You should only ever have one editor at a time.
-}
editor : Html msg
editor =
    div
        [ class "code-editor"
        , id "ace-code-editor"
        ]
        []
