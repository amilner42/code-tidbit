module Pages.ViewSnipbit.Model exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Completed exposing (IsCompleted)
import Models.Snipbit exposing (Snipbit, HighlightedComment)
import Models.ViewerRelevantHC exposing (ViewerRelevantHC, browsingFrames)


{-| `ViewSnipbit` model.
-}
type alias Model =
    { snipbit : Maybe Snipbit
    , isCompleted : Maybe IsCompleted
    , relevantHC : Maybe ViewingSnipbitRelevantHC
    }


{-| Used when viewing a snipbit and the user highlights part of the code.
-}
type alias ViewingSnipbitRelevantHC =
    ViewerRelevantHC HighlightedComment


{-| Returns true if the user is browsing the snipbit viewer relevant HC.
-}
isViewSnipbitRHCTabOpen : Model -> Bool
isViewSnipbitRHCTabOpen model =
    maybeMapWithDefault
        browsingFrames
        False
        model.relevantHC


{-| `snipbit` field updater.
-}
updateViewingSnipbit : (Snipbit -> Snipbit) -> Model -> Model
updateViewingSnipbit updater model =
    { model | snipbit = Maybe.map updater model.snipbit }


{-| `isCompleted` field updater.
-}
updateViewingSnipbitIsCompleted : (IsCompleted -> IsCompleted) -> Model -> Model
updateViewingSnipbitIsCompleted updater model =
    { model | isCompleted = Maybe.map updater model.isCompleted }


{-| `relevantHC` field updater.
-}
updateViewingSnipbitRelevantHC : (ViewingSnipbitRelevantHC -> ViewingSnipbitRelevantHC) -> Model -> Model
updateViewingSnipbitRelevantHC updater model =
    { model | relevantHC = Maybe.map updater model.relevantHC }


{-| `snipbit` field setter.
-}
setViewingSnipbit : Maybe Snipbit -> Model -> Model
setViewingSnipbit maybeSnipbit model =
    { model | snipbit = maybeSnipbit }


{-| `isCompleted` field setter.
-}
setViewingSnipbitIsCompleted : Maybe IsCompleted -> Model -> Model
setViewingSnipbitIsCompleted maybeIsCompleted model =
    { model | isCompleted = maybeIsCompleted }


{-| `relevantHC` field setter.
-}
setViewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC -> Model -> Model
setViewingSnipbitRelevantHC maybeRelevantHC model =
    { model | relevantHC = maybeRelevantHC }
