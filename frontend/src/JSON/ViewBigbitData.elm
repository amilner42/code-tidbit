module JSON.ViewBigbitData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Bigbit as JSONBigbit
import JSON.Completed as JSONCompleted
import JSON.ViewerRelevantHC as JSONViewerRelevantHC
import Models.ViewBigbitData exposing (..)


{-| `ViewingBigbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingBigbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSONViewerRelevantHC.encoder JSONBigbit.publicationHighlightedCommentEncoder


{-| `ViewingBigbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingBigbitRelevantHC
relevantHCDecoder =
    JSONViewerRelevantHC.decoder JSONBigbit.publicationHighlightedCommentDecoder


{-| `ViewBigbitData` encoder.
-}
encoder : ViewBigbitData -> Encode.Value
encoder viewBigbitData =
    Encode.object
        [ ( "viewingBigbit"
          , Util.justValueOrNull JSONBigbit.encoder viewBigbitData.viewingBigbit
          )
        , ( "viewingBigbitIsCompleted"
          , Util.justValueOrNull JSONCompleted.isCompletedEncoder viewBigbitData.viewingBigbitIsCompleted
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
        |> required "viewingBigbit" (Decode.maybe JSONBigbit.decoder)
        |> required "viewingBigbitIsCompleted" (Decode.maybe JSONCompleted.isCompletedDecoder)
        |> required "viewingBigbitRelevantHC" (Decode.maybe relevantHCDecoder)
