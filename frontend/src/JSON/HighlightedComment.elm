module JSON.HighlightedComment exposing (..)

import DefaultServices.Util as Util
import JSON.Range
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.HighlightedComment exposing (..)
import Models.Range as Range


{-| `HighlightedComment` encoder.
-}
encoder : HighlightedComment -> Encode.Value
encoder hc =
    Encode.object
        [ ( "range", JSON.Range.encoder hc.range )
        , ( "comment", Encode.string hc.comment )
        ]


{-| `HighlightedComment` decoder.
-}
decoder : Decode.Decoder HighlightedComment
decoder =
    decode HighlightedComment
        |> required "range" JSON.Range.decoder
        |> required "comment" Decode.string


{-| `MaybeHighlightedComment` encoder.
-}
maybeEncoder : MaybeHighlightedComment -> Encode.Value
maybeEncoder maybeHighlightedComment =
    Encode.object
        [ ( "range"
          , Util.justValueOrNull
                JSON.Range.encoder
                maybeHighlightedComment.range
          )
        , ( "comment"
          , Util.justValueOrNull
                Encode.string
                maybeHighlightedComment.comment
          )
        ]


{-| `MaybeHighlightedComment` decoder.
-}
maybeDecoder : Decode.Decoder MaybeHighlightedComment
maybeDecoder =
    decode MaybeHighlightedComment
        |> required "range" (Decode.maybe JSON.Range.decoder)
        |> required "comment" (Decode.maybe Decode.string)
