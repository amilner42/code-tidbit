module Pages.ViewBigbit.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Bigbit
import JSON.Completed
import JSON.ViewerRelevantHC
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.ViewBigbit.Model exposing (..)


{-| `ViewBigbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "bigbit", Util.justValueOrNull JSON.Bigbit.encoder model.bigbit )
        , ( "isCompleted", Util.justValueOrNull JSON.Completed.isCompletedEncoder model.isCompleted )
        , ( "relevantHC", Util.justValueOrNull relevantHCEncoder model.relevantHC )
        ]


{-| `ViewBigbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "bigbit" (Decode.maybe JSON.Bigbit.decoder)
        |> required "isCompleted" (Decode.maybe JSON.Completed.isCompletedDecoder)
        |> required "relevantHC" (Decode.maybe relevantHCDecoder)


{-| `ViewingBigbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingBigbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSON.ViewerRelevantHC.encoder JSON.Bigbit.highlightedCommentEncoder


{-| `ViewingBigbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingBigbitRelevantHC
relevantHCDecoder =
    JSON.ViewerRelevantHC.decoder JSON.Bigbit.highlightedCommentDecoder
