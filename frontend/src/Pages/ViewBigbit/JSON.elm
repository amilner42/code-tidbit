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
encoder viewBigbitData =
    Encode.object
        [ ( "viewingBigbit", Util.justValueOrNull JSON.Bigbit.encoder viewBigbitData.viewingBigbit )
        , ( "viewingBigbitIsCompleted"
          , Util.justValueOrNull JSON.Completed.isCompletedEncoder viewBigbitData.viewingBigbitIsCompleted
          )
        , ( "viewingBigbitRelevantHC", Util.justValueOrNull relevantHCEncoder viewBigbitData.viewingBigbitRelevantHC )
        ]


{-| `ViewBigbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "viewingBigbit" (Decode.maybe JSON.Bigbit.decoder)
        |> required "viewingBigbitIsCompleted" (Decode.maybe JSON.Completed.isCompletedDecoder)
        |> required "viewingBigbitRelevantHC" (Decode.maybe relevantHCDecoder)


{-| `ViewingBigbitRelevantHC` encoder.
-}
relevantHCEncoder : ViewingBigbitRelevantHC -> Encode.Value
relevantHCEncoder =
    JSON.ViewerRelevantHC.encoder
        JSON.Bigbit.publicationHighlightedCommentEncoder


{-| `ViewingBigbitRelevantHC` decoder.
-}
relevantHCDecoder : Decode.Decoder ViewingBigbitRelevantHC
relevantHCDecoder =
    JSON.ViewerRelevantHC.decoder
        JSON.Bigbit.publicationHighlightedCommentDecoder
