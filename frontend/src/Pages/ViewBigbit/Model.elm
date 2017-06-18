module Pages.ViewBigbit.Model exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Bigbit exposing (Bigbit, HighlightedComment, isFSOpen)
import Models.Completed exposing (IsCompleted)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.QA exposing (BigbitCodePointer, BigbitQA, BigbitQAState, BigbitQuestion)
import Models.Route as Route
import Models.TutorialBookmark as TB
import Models.ViewerRelevantHC exposing (ViewerRelevantHC, browsingFrames)


{-| All the data for viewing a bigbit.
-}
type alias Model =
    { bigbit : Maybe Bigbit
    , isCompleted : Maybe IsCompleted
    , possibleOpinion : Maybe PossibleOpinion
    , relevantHC : Maybe ViewingBigbitRelevantHC
    , qa : Maybe BigbitQA
    , relevantQuestions : Maybe (List BigbitQuestion)
    , bookmark : TB.TutorialBookmark
    , qaState : BigbitQAState
    , tutorialCodePointer : Maybe BigbitCodePointer
    }


{-| Used when viewing a bigbit and the user highlights part of the code.
-}
type alias ViewingBigbitRelevantHC =
    ViewerRelevantHC HighlightedComment


{-| `bigbit` field updater.
-}
updateBigbit : (Bigbit -> Bigbit) -> Model -> Model
updateBigbit updater model =
    { model | bigbit = Maybe.map updater model.bigbit }


{-| `isCompleted` field updater.
-}
updateIsCompleted : (IsCompleted -> IsCompleted) -> Model -> Model
updateIsCompleted updater model =
    { model | isCompleted = Maybe.map updater model.isCompleted }


{-| `relevantHC` field updater.
-}
updateRelevantHC : (ViewingBigbitRelevantHC -> ViewingBigbitRelevantHC) -> Model -> Model
updateRelevantHC updater model =
    { model | relevantHC = Maybe.map updater model.relevantHC }


{-| Sets `bigbit`.
-}
setBigbit : Maybe Bigbit -> Model -> Model
setBigbit maybeBigbit model =
    { model | bigbit = maybeBigbit }


{-| Sets `isCompleted`.
-}
setIsCompleted : Maybe IsCompleted -> Model -> Model
setIsCompleted maybeIsCompleted model =
    { model | isCompleted = maybeIsCompleted }


{-| Sets `bigbit`.
-}
setRelevantHC : Maybe ViewingBigbitRelevantHC -> Model -> Model
setRelevantHC maybeRelevantHC model =
    { model | relevantHC = maybeRelevantHC }


{-| Returns true if the user is currently browsing the RHC.
-}
isBigbitRHCTabOpen : Maybe ViewingBigbitRelevantHC -> Bool
isBigbitRHCTabOpen =
    maybeMapWithDefault browsingFrames False


{-| Returns true if the FS is open.
-}
isBigbitFSOpen : Maybe Bigbit -> Bool
isBigbitFSOpen =
    Maybe.map .fs >> maybeMapWithDefault isFSOpen False


{-| Get's the route from the bookmark.

Resumes to the tutorial itself, not the browsing-file state, so the current file is set to `Nothing`.

-}
routeForBookmark : Maybe String -> String -> TB.TutorialBookmark -> Route.Route
routeForBookmark maybeStoryID bigbitID bookmark =
    case bookmark of
        TB.Introduction ->
            Route.ViewBigbitIntroductionPage maybeStoryID bigbitID Nothing

        TB.FrameNumber frameNumber ->
            Route.ViewBigbitFramePage maybeStoryID bigbitID frameNumber Nothing

        TB.Conclusion ->
            Route.ViewBigbitConclusionPage maybeStoryID bigbitID Nothing
