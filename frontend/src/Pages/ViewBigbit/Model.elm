module Pages.ViewBigbit.Model exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Bigbit exposing (Bigbit, BigbitHighlightedCommentForPublication, isFSOpen)
import Models.Completed exposing (IsCompleted)
import Models.ViewerRelevantHC exposing (ViewerRelevantHC, browsingFrames)


{-| All the data for viewing a bigbit.
-}
type alias Model =
    { viewingBigbit : Maybe Bigbit
    , viewingBigbitIsCompleted : Maybe IsCompleted
    , viewingBigbitRelevantHC : Maybe ViewingBigbitRelevantHC
    }


{-| Used when viewing a bigbit and the user highlights part of the code.
-}
type alias ViewingBigbitRelevantHC =
    ViewerRelevantHC BigbitHighlightedCommentForPublication


{-| `viewingBigbit` field updater.
-}
updateViewingBigbit : (Bigbit -> Bigbit) -> Model -> Model
updateViewingBigbit updater model =
    { model | viewingBigbit = Maybe.map updater model.viewingBigbit }


{-| `viewingBigbitIsCompleted` field updater.
-}
updateViewingBigbitIsCompleted : (IsCompleted -> IsCompleted) -> Model -> Model
updateViewingBigbitIsCompleted updater model =
    { model | viewingBigbitIsCompleted = Maybe.map updater model.viewingBigbitIsCompleted }


{-| `viewingBigbitRelevantHC` field updater.
-}
updateViewingBigbitRelevantHC : (ViewingBigbitRelevantHC -> ViewingBigbitRelevantHC) -> Model -> Model
updateViewingBigbitRelevantHC updater model =
    { model | viewingBigbitRelevantHC = Maybe.map updater model.viewingBigbitRelevantHC }


{-| Sets `viewingBigbit`.
-}
setViewingBigbit : Maybe Bigbit -> Model -> Model
setViewingBigbit maybeBigbit model =
    { model | viewingBigbit = maybeBigbit }


{-| Sets `viewingBigbitIsCompleted`.
-}
setViewingBigbitIsCompleted : Maybe IsCompleted -> Model -> Model
setViewingBigbitIsCompleted maybeIsCompleted model =
    { model | viewingBigbitIsCompleted = maybeIsCompleted }


{-| Sets `viewingBigbit`.
-}
setViewingBigbitRelevantHC : Maybe ViewingBigbitRelevantHC -> Model -> Model
setViewingBigbitRelevantHC maybeRelevantHC model =
    { model | viewingBigbitRelevantHC = maybeRelevantHC }


{-| Returns true if the user is currently browsing the RHC.
-}
isViewBigbitRHCTabOpen : Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitRHCTabOpen =
    maybeMapWithDefault browsingFrames False


{-| Returns true if the user is currently browsing the FS.
-}
isViewBigbitFSTabOpen : Maybe Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitFSTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC) && isViewBigbitFSOpen maybeBigbit


{-| Returns true if the FS is open, this ISNT the same as the FS tab being open,
the FS can be open but have the browsing-rhc over-top it.
-}
isViewBigbitFSOpen : Maybe Bigbit -> Bool
isViewBigbitFSOpen =
    Maybe.map .fs
        >> maybeMapWithDefault isFSOpen False


{-| Returns true if the user is currently browsing the tutorial.
-}
isViewBigbitTutorialTabOpen : Maybe Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitTutorialTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC) && (not <| isViewBigbitFSTabOpen maybeBigbit maybeRHC)
