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


{-| `ViewSnipbitModel` encoder.
-}
encoder : Model -> Encode.Value
encoder viewSnipbitData =
    Encode.object
        [ ( "viewingSnipbit"
          , Util.justValueOrNull
                JSON.Snipbit.encoder
                viewSnipbitData.viewingSnipbit
          )
        , ( "viewingSnipbitIsCompleted"
          , Util.justValueOrNull
                JSON.Completed.isCompletedEncoder
                viewSnipbitData.viewingSnipbitIsCompleted
          )
        , ( "viewingSnipbitRelevantHC"
          , Util.justValueOrNull
                relevantHCEncoder
                viewSnipbitData.viewingSnipbitRelevantHC
          )
        ]


{-| `ViewSnipbitModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "viewingSnipbit"
            (Decode.maybe JSON.Snipbit.decoder)
        |> required "viewingSnipbitIsCompleted"
            (Decode.maybe JSON.Completed.isCompletedDecoder)
        |> required "viewingSnipbitRelevantHC"
            (Decode.maybe relevantHCDecoder)
