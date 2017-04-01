module Models.Content exposing (..)

import Models.Bigbit exposing (Bigbit)
import Models.Snipbit exposing (Snipbit)
import Models.Story exposing (Story)


{-| Content represents all of the possible user-created content.
-}
type Content
    = Snipbit Snipbit
    | Bigbit Bigbit
    | Story Story
