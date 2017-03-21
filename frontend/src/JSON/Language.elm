module JSON.Language exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Elements.Editor exposing (..)


{-| `Language` encoder.
-}
encoder : Language -> Encode.Value
encoder =
    toString >> Encode.string


{-| `Language` decoder.
-}
decoder : Decode.Decoder Language
decoder =
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

                "C" ->
                    Decode.succeed C

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

                "HAML" ->
                    Decode.succeed HAML

                "HTML" ->
                    Decode.succeed HTML

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

                "SASS" ->
                    Decode.succeed SASS

                "Scala" ->
                    Decode.succeed Scala

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

                "YAML" ->
                    Decode.succeed YAML

                _ ->
                    Decode.fail <| encodedLanguage ++ " is not a valid encoded string."
    in
        Decode.string
            |> Decode.andThen fromStringDecoder
