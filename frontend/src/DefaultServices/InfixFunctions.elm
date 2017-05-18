module DefaultServices.InfixFunctions exposing (..)


{- This module is intended to have all it's content imported [`import DefaultServices.InfixFunctions exposing (..)`] so
   be careful to use names that won't conflict with external names and make sure that the operators are generic enough
   that it makes sense for them to be imported by default.
-}


{-| An alias for `Maybe.map`.

Purposefully a similar ligature to |> as it has the same infix-function-application style.
-}
(||>) : Maybe a -> (a -> b) -> Maybe b
(||>) maybeA func =
    Maybe.map func maybeA
