module Pages.ViewSnipbit.Init exposing (..)

import Dict
import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` init.
-}
init : Model
init =
    { snipbit = Nothing
    , isCompleted = Nothing
    , possibleOpinion = Nothing
    , relevantHC = Nothing
    , qa = Nothing
    , relevantQuestions = Nothing
    , bookmark = 1
    , qaState = Dict.empty
    , tutorialCodePointer = Nothing
    }
