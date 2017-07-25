module Pages.ViewSnipbit.Init exposing (..)

import Dict
import Models.TutorialBookmark as TB
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
    , bookmark = TB.Introduction
    , qaState = Dict.empty
    , tutorialCodePointer = Nothing
    }
