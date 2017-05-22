module DefaultServices.InfixFunctions exposing (..)

import Maybe


{- This module is intended to have all it's content imported [`import DefaultServices.InfixFunctions exposing (..)`] so
   be careful to use names that won't conflict with external names and make sure that the operators are generic enough
   that it makes sense for them to be imported by default.
-}


{-| An alias for `Maybe.map`.

Purposefully a similar ligature to |> as it has the same type but with `Maybe`.
-}
(||>) : Maybe a -> (a -> b) -> Maybe b
(||>) maybeA func =
    Maybe.map func maybeA
infixl 0 ||>


{-| An alias for `Maybe.map`.

Purposefully a similar ligature to <| as it has the same type but with `Maybe`.
-}
(<||) : (a -> b) -> Maybe a -> Maybe b
(<||) func maybeA =
    Maybe.map func maybeA
infixr 0 <||


{-| An alias for `Maybe.andThen`.

Purposefully a similar ligature to |> as it has the same type but with `Maybe`s.
-}
(|||>) : Maybe a -> (a -> Maybe b) -> Maybe b
(|||>) maybeA func =
    Maybe.andThen func maybeA
infixl 0 |||>


{-| An alias for `Maybe.andThen`.

Purposefully a similar ligature to <| as it has the same type but with `Maybe`s.
-}
(<|||) : (a -> Maybe b) -> Maybe a -> Maybe b
(<|||) func maybeA =
    Maybe.andThen func maybeA
infixr 0 <|||


{-| An alias for `Maybe.withDefault`.

Purposefully a similar ligature to `|>`, meant to be used in a `|>` chain.
-}
(?>) : Maybe a -> a -> a
(?>) maybeA defaultA =
    Maybe.withDefault defaultA maybeA
infixl 0 ?>


{-| An alias for `Maybe.withDefault`.

Purposefully a similar ligature to `<|`, meant to be used in a `<|` chain.
-}
(<?) : a -> Maybe a -> a
(<?) defaultA maybeA =
    Maybe.withDefault defaultA maybeA
infixr 0 <?


{-| For adding a slash between 2 strings.
-}
(:/:) : String -> String -> String
(:/:) str1 str2 =
    str1 ++ "/" ++ str2
infixl 0 :/:
