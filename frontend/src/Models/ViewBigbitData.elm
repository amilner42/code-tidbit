module Models.ViewBigbitData exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Bigbit as Bigbit
import Models.Completed as Completed
import Models.ViewerRelevantHC as ViewerRelevantHC


{-| All the data for viewing a bigbit.
-}
type alias ViewBigbitData =
    { viewingBigbit : Maybe Bigbit.Bigbit
    , viewingBigbitIsCompleted : Maybe Completed.IsCompleted
    , viewingBigbitRelevantHC : Maybe ViewingBigbitRelevantHC
    }


{-| Used when viewing a bigbit and the user highlights part of the code.
-}
type alias ViewingBigbitRelevantHC =
    ViewerRelevantHC.ViewerRelevantHC Bigbit.BigbitHighlightedCommentForPublication


{-| `viewingBigbit` field updater.
-}
updateViewingBigbit : (Bigbit.Bigbit -> Bigbit.Bigbit) -> ViewBigbitData -> ViewBigbitData
updateViewingBigbit updater viewBigbitData =
    { viewBigbitData
        | viewingBigbit = Maybe.map updater viewBigbitData.viewingBigbit
    }


{-| `viewingBigbitIsCompleted` field updater.
-}
updateViewingBigbitIsCompleted : (Completed.IsCompleted -> Completed.IsCompleted) -> ViewBigbitData -> ViewBigbitData
updateViewingBigbitIsCompleted updater viewBigbitData =
    { viewBigbitData
        | viewingBigbitIsCompleted = Maybe.map updater viewBigbitData.viewingBigbitIsCompleted
    }


{-| `viewingBigbitRelevantHC` field updater.
-}
updateViewingBigbitRelevantHC : (ViewingBigbitRelevantHC -> ViewingBigbitRelevantHC) -> ViewBigbitData -> ViewBigbitData
updateViewingBigbitRelevantHC updater viewBigbitData =
    { viewBigbitData
        | viewingBigbitRelevantHC = Maybe.map updater viewBigbitData.viewingBigbitRelevantHC
    }


{-| Sets `viewingBigbit`.
-}
setViewingBigbit : Maybe Bigbit.Bigbit -> ViewBigbitData -> ViewBigbitData
setViewingBigbit maybeBigbit viewBigbitData =
    { viewBigbitData
        | viewingBigbit = maybeBigbit
    }


{-| Sets `viewingBigbitIsCompleted`.
-}
setViewingBigbitIsCompleted : Maybe Completed.IsCompleted -> ViewBigbitData -> ViewBigbitData
setViewingBigbitIsCompleted maybeIsCompleted viewBigbitData =
    { viewBigbitData
        | viewingBigbitIsCompleted = maybeIsCompleted
    }


{-| Sets `viewingBigbit`.
-}
setViewingBigbitRelevantHC : Maybe ViewingBigbitRelevantHC -> ViewBigbitData -> ViewBigbitData
setViewingBigbitRelevantHC maybeRelevantHC viewBigbitData =
    { viewBigbitData
        | viewingBigbitRelevantHC = maybeRelevantHC
    }


{-| Returns true if the user is currently browsing the RHC.
-}
isViewBigbitRHCTabOpen : Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitRHCTabOpen =
    maybeMapWithDefault ViewerRelevantHC.browsingFrames False


{-| Returns true if the user is currently browsing the FS.
-}
isViewBigbitFSTabOpen : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitFSTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC)
        && isViewBigbitFSOpen maybeBigbit


{-| Returns true if the FS is open, this ISNT the same as the FS tab being open,
the FS can be open but have the browsing-rhc over-top it.
-}
isViewBigbitFSOpen : Maybe Bigbit.Bigbit -> Bool
isViewBigbitFSOpen =
    Maybe.map .fs
        >> maybeMapWithDefault Bigbit.isFSOpen False


{-| Returns true if the user is currently browsing the tutorial.
-}
isViewBigbitTutorialTabOpen : Maybe Bigbit.Bigbit -> Maybe ViewingBigbitRelevantHC -> Bool
isViewBigbitTutorialTabOpen maybeBigbit maybeRHC =
    (not <| isViewBigbitRHCTabOpen maybeRHC)
        && (not <| isViewBigbitFSTabOpen maybeBigbit maybeRHC)


{-| Default `ViewBigbitData` for init.
-}
defaultViewBigbitData : ViewBigbitData
defaultViewBigbitData =
    ViewBigbitData Nothing Nothing Nothing
