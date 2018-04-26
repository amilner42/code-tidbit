module Pages.ViewBigbit.Init exposing (..)

import Dict
import Pages.ViewBigbit.Model exposing (Model)


{-| `ViewBigbit` model.
-}
init : Model
init =
    { bigbit = Nothing
    , isCompleted = Nothing
    , possibleOpinion = Nothing
    , relevantHC = Nothing
    , qa = Nothing
    , relevantQuestions = Nothing
    , bookmark = 1
    , qaState = Dict.empty
    , tutorialCodePointer = Nothing
    }
