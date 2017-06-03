module Pages.ViewBigbit.Init exposing (..)

import Dict
import Models.TutorialBookmark as TB
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
    , bookmark = TB.Introduction
    , qaState = Dict.empty
    , tutorialCodePointer = Nothing
    }
