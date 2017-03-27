module Pages.ViewSnipbit.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Completed
import JSON.Snipbit
import JSON.ViewerRelevantHC
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "snipbit", Util.justValueOrNull JSON.Snipbit.encoder model.snipbit )
        , ( "isCompleted", Util.justValueOrNull JSON.Completed.isCompletedEncoder model.isCompleted )
        , ( "relevantHC", Util.justValueOrNull relevantHCEncoder model.relevantHC )
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
    JSON.ViewerRelevantHC.encoder JSON.Snipbit.hcEncoder


{-| `ViewingSnipbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingSnipbitRelevantHC
relevantHCDecoder =
    JSON.ViewerRelevantHC.decoder JSON.Snipbit.hcDecoder
