module Pages.ViewBigbit.Init exposing (..)

import Pages.ViewBigbit.Model exposing (Model)


{-| `ViewBigbit` model.
-}
init : Model
init =
    { viewingBigbit = Nothing
    , viewingBigbitIsCompleted = Nothing
    , viewingBigbitRelevantHC = Nothing
    }
