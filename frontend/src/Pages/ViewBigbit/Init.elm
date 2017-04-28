module Pages.ViewBigbit.Init exposing (..)

import Pages.ViewBigbit.Model exposing (Model)


{-| `ViewBigbit` model.
-}
init : Model
init =
    { bigbit = Nothing
    , isCompleted = Nothing
    , maybeOpinion = Nothing
    , relevantHC = Nothing
    }
