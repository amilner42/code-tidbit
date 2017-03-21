module JSON.ViewSnipbitData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Completed as JSONCompleted
import JSON.HighlightedComment as JSONHC
import JSON.Snipbit as JSONSnipbit
import JSON.ViewerRelevantHC as JSONViewerRelevantHC
import Models.ViewSnipbitData exposing (..)


{-| `ViewingSnipbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingSnipbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSONViewerRelevantHC.encoder JSONHC.encoder


{-| `ViewingSnipbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingSnipbitRelevantHC
relevantHCDecoder =
    JSONViewerRelevantHC.decoder JSONHC.decoder


{-| `ViewSnipbitData` encoder.
-}
encoder : ViewSnipbitData -> Encode.Value
encoder viewSnipbitData =
    Encode.object
        [ ( "viewingSnipbit"
          , Util.justValueOrNull JSONSnipbit.encoder viewSnipbitData.viewingSnipbit
          )
        , ( "viewingSnipbitIsCompleted"
          , Util.justValueOrNull JSONCompleted.isCompletedEncoder viewSnipbitData.viewingSnipbitIsCompleted
          )
        , ( "viewingSnipbitRelevantHC"
          , Util.justValueOrNull relevantHCEncoder viewSnipbitData.viewingSnipbitRelevantHC
          )
        ]


{-| `ViewSnipbitData` decoder.
-}
decoder : Decode.Decoder ViewSnipbitData
decoder =
    decode ViewSnipbitData
        |> required "viewingSnipbit" (Decode.maybe JSONSnipbit.decoder)
        |> required "viewingSnipbitIsCompleted" (Decode.maybe JSONCompleted.isCompletedDecoder)
        |> required "viewingSnipbitRelevantHC" (Decode.maybe relevantHCDecoder)
