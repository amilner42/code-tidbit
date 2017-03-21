module JSON.HighlightedComment exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.Range as JSONRange
import Models.HighlightedComment exposing (..)
import Models.Range as Range


{-| `HighlightedComment` encoder.
-}
encoder : HighlightedComment -> Encode.Value
encoder hc =
    Encode.object
        [ ( "range", JSONRange.encoder hc.range )
        , ( "comment", Encode.string hc.comment )
        ]


{-| `HighlightedComment` decoder.
-}
decoder : Decode.Decoder HighlightedComment
decoder =
    Decode.map2 HighlightedComment
        (Decode.field "range" JSONRange.decoder)
        (Decode.field "comment" Decode.string)


{-| `MaybeHighlightedComment` encoder.
-}
maybeEncoder : MaybeHighlightedComment -> Encode.Value
maybeEncoder maybeHighlightedComment =
    Encode.object
        [ ( "range"
          , Util.justValueOrNull
                JSONRange.encoder
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
        |> required "range" (Decode.maybe JSONRange.decoder)
        |> required "comment" (Decode.maybe Decode.string)
