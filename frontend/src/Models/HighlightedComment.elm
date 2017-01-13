module Models.HighlightedComment exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Models.Range as Range


{-| A highlighted comment, currently used in basic tidbits.
-}
type alias HighlightedComment =
    { range : Range.Range
    , comment : String
    }


{-| HighlightedComment `cacheEncoder`.
-}
highlightedCommentCacheEncoder : HighlightedComment -> Encode.Value
highlightedCommentCacheEncoder highlightedComment =
    Encode.object
        [ ( "range", Range.rangeCacheEncoder highlightedComment.range )
        , ( "comment", Encode.string highlightedComment.comment )
        ]


{-| HighlightedComment `cacheDecoder`.
-}
highlightedCommentCacheDecoder : Decode.Decoder HighlightedComment
highlightedCommentCacheDecoder =
    Decode.map2 HighlightedComment
        (Decode.field "range" Range.rangeCacheDecoder)
        (Decode.field "comment" Decode.string)
