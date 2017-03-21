module JSON.ViewBigbitData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit
import JSON.Completed
import JSON.ViewerRelevantHC
import Models.ViewBigbitData exposing (..)


{-| `ViewingBigbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingBigbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSON.ViewerRelevantHC.encoder JSON.Bigbit.publicationHighlightedCommentEncoder


{-| `ViewingBigbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingBigbitRelevantHC
relevantHCDecoder =
    JSON.ViewerRelevantHC.decoder JSON.Bigbit.publicationHighlightedCommentDecoder


{-| `ViewBigbitData` encoder.
-}
encoder : ViewBigbitData -> Encode.Value
encoder viewBigbitData =
    Encode.object
        [ ( "viewingBigbit"
          , Util.justValueOrNull JSON.Bigbit.encoder viewBigbitData.viewingBigbit
          )
        , ( "viewingBigbitIsCompleted"
          , Util.justValueOrNull JSON.Completed.isCompletedEncoder viewBigbitData.viewingBigbitIsCompleted
          )
        , ( "viewingBigbitRelevantHC"
          , Util.justValueOrNull relevantHCEncoder viewBigbitData.viewingBigbitRelevantHC
          )
        ]


{-| `ViewBigbitData` decoder.
-}
decoder : Decode.Decoder ViewBigbitData
decoder =
    decode ViewBigbitData
        |> required "viewingBigbit" (Decode.maybe JSON.Bigbit.decoder)
        |> required "viewingBigbitIsCompleted" (Decode.maybe JSON.Completed.isCompletedDecoder)
        |> required "viewingBigbitRelevantHC" (Decode.maybe relevantHCDecoder)
