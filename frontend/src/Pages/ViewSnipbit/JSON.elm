module Pages.ViewSnipbit.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Completed
import JSON.HighlightedComment
import JSON.Snipbit
import JSON.ViewerRelevantHC
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` encoder.
-}
encoder : Model -> Encode.Value
encoder viewSnipbitData =
    Encode.object
        [ ( "snipbit", Util.justValueOrNull JSON.Snipbit.encoder viewSnipbitData.snipbit )
        , ( "isCompleted", Util.justValueOrNull JSON.Completed.isCompletedEncoder viewSnipbitData.isCompleted )
        , ( "relevantHC", Util.justValueOrNull relevantHCEncoder viewSnipbitData.relevantHC )
        ]


{-| `ViewSnipbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "snipbit" (Decode.maybe JSON.Snipbit.decoder)
        |> required "isCompleted" (Decode.maybe JSON.Completed.isCompletedDecoder)
        |> required "relevantHC" (Decode.maybe relevantHCDecoder)


{-| `ViewingSnipbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingSnipbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSON.ViewerRelevantHC.encoder JSON.HighlightedComment.encoder


{-| `ViewingSnipbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingSnipbitRelevantHC
relevantHCDecoder =
    JSON.ViewerRelevantHC.decoder JSON.HighlightedComment.decoder
