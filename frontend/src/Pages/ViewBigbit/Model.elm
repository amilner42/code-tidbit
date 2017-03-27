module Pages.ViewBigbit.Model exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Bigbit exposing (Bigbit, HighlightedComment, isFSOpen)
import Models.Completed exposing (IsCompleted)
import Models.ViewerRelevantHC exposing (ViewerRelevantHC, browsingFrames)


{-| All the data for viewing a bigbit.
-}
type alias Model =
    { bigbit : Maybe Bigbit
    , isCompleted : Maybe IsCompleted
    , relevantHC : Maybe ViewingBigbitRelevantHC
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


{-| Returns true if the user is currently browsing the FS.
-}
isBigbitFSTabOpen : Maybe Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isBigbitFSTabOpen maybeBigbit maybeRHC =
    (not <| isBigbitRHCTabOpen maybeRHC) && isBigbitFSOpen maybeBigbit


{-| Returns true if the FS is open, this is NOT the same as the FS tab being open,
the FS can be open but have the browsing-rhc over-top it.
-}
isBigbitFSOpen : Maybe Bigbit -> Bool
isBigbitFSOpen =
    Maybe.map .fs
        >> maybeMapWithDefault isFSOpen False


{-| Returns true if the user is currently browsing the tutorial.
-}
isBigbitTutorialTabOpen : Maybe Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isBigbitTutorialTabOpen maybeBigbit maybeRHC =
    (not <| isBigbitRHCTabOpen maybeRHC) && (not <| isBigbitFSTabOpen maybeBigbit maybeRHC)
