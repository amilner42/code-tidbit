module Models.ViewSnipbitData exposing (..)

import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Completed as Completed
import Models.HighlightedComment as HC
import Models.Snipbit as Snipbit
import Models.ViewerRelevantHC as ViewerRelevantHC


{-| All the data for viewing a snipbit.
-}
type alias ViewSnipbitData =
    { viewingSnipbit : Maybe Snipbit.Snipbit
    , viewingSnipbitIsCompleted : Maybe Completed.IsCompleted
    , viewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC
    }


{-| Used when viewing a snipbit and the user highlights part of the code.
-}
type alias ViewingSnipbitRelevantHC =
    ViewerRelevantHC.ViewerRelevantHC HC.HighlightedComment


{-| `viewingSnipbit` field updater.
-}
updateViewingSnipbit : (Snipbit.Snipbit -> Snipbit.Snipbit) -> ViewSnipbitData -> ViewSnipbitData
updateViewingSnipbit updater viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbit = Maybe.map updater viewSnipbitData.viewingSnipbit
    }


{-| `viewingSnipbitIsCompleted` field updater.
-}
updateViewingSnipbitIsCompleted : (Completed.IsCompleted -> Completed.IsCompleted) -> ViewSnipbitData -> ViewSnipbitData
updateViewingSnipbitIsCompleted updater viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbitIsCompleted = Maybe.map updater viewSnipbitData.viewingSnipbitIsCompleted
    }


{-| `viewingSnipbitRelevantHC` field updater.
-}
updateViewingSnipbitRelevantHC : (ViewingSnipbitRelevantHC -> ViewingSnipbitRelevantHC) -> ViewSnipbitData -> ViewSnipbitData
updateViewingSnipbitRelevantHC updater viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbitRelevantHC = Maybe.map updater viewSnipbitData.viewingSnipbitRelevantHC
    }


{-| Sets the `viewingSnipbit`.
-}
setViewingSnipbit : Maybe Snipbit.Snipbit -> ViewSnipbitData -> ViewSnipbitData
setViewingSnipbit maybeSnipbit viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbit = maybeSnipbit
    }


{-| Sets the `viewingSnipbitIsCompleted`.
-}
setViewingSnipbitIsCompleted : Maybe Completed.IsCompleted -> ViewSnipbitData -> ViewSnipbitData
setViewingSnipbitIsCompleted maybeIsCompleted viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbitIsCompleted = maybeIsCompleted
    }


{-| Sets the `viewingSnipbitRelevantHC`.
-}
setViewingSnipbitRelevantHC : Maybe ViewingSnipbitRelevantHC -> ViewSnipbitData -> ViewSnipbitData
setViewingSnipbitRelevantHC maybeRelevantHC viewSnipbitData =
    { viewSnipbitData
        | viewingSnipbitRelevantHC = maybeRelevantHC
    }


{-| ViewingSnipbitRelevantHC `cacheEncoder`.
-}
viewingSnipbitRelevantHCCacheEncoder : ViewingSnipbitRelevantHC -> Encode.Value
viewingSnipbitRelevantHCCacheEncoder =
    ViewerRelevantHC.encoder HC.highlightedCommentEncoder


{-| ViewingSnipbitRelevantHC `cacheDecoder`.
-}
viewingSnipbitRelevantHCCacheDecoder : Decode.Decoder ViewingSnipbitRelevantHC
viewingSnipbitRelevantHCCacheDecoder =
    ViewerRelevantHC.decoder HC.highlightedCommentDecoder


{-| Returns true if the user is browsing the snipbit viewer relevant HC.
-}
isViewSnipbitRHCTabOpen : ViewSnipbitData -> Bool
isViewSnipbitRHCTabOpen viewSnipbitData =
    maybeMapWithDefault
        ViewerRelevantHC.browsingFrames
        False
        viewSnipbitData.viewingSnipbitRelevantHC


{-| Default `ViewSnipbitData` for init.
-}
defaultViewSnipbitData : ViewSnipbitData
defaultViewSnipbitData =
    ViewSnipbitData Nothing Nothing Nothing


{-| ViewSnipbitData encoder.
-}
encoder : ViewSnipbitData -> Encode.Value
encoder viewSnipbitData =
    Encode.object
        [ ( "viewingSnipbit", Util.justValueOrNull Snipbit.snipbitCacheEncoder viewSnipbitData.viewingSnipbit )
        , ( "viewingSnipbitIsCompleted", Util.justValueOrNull Completed.isCompletedEncoder viewSnipbitData.viewingSnipbitIsCompleted )
        , ( "viewingSnipbitRelevantHC"
          , Util.justValueOrNull viewingSnipbitRelevantHCCacheEncoder viewSnipbitData.viewingSnipbitRelevantHC
          )
        ]


{-| ViewSnipbitData decoder.
-}
decoder : Decode.Decoder ViewSnipbitData
decoder =
    decode ViewSnipbitData
        |> required "viewingSnipbit" (Decode.maybe Snipbit.snipbitCacheDecoder)
        |> required "viewingSnipbitIsCompleted" (Decode.maybe Completed.isCompletedDecoder)
        |> required "viewingSnipbitRelevantHC" (Decode.maybe viewingSnipbitRelevantHCCacheDecoder)
