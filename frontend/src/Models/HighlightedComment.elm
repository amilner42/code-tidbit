module Models.HighlightedComment exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Models.Range as Range


{-| A maybe highlighted comment, currently used in basic tidbits for the
creation of highlighted comments.
-}
type alias MaybeHighlightedComment =
    { range : Maybe Range.Range
    , comment : Maybe String
    }


{-| MaybeHighlightedComment `cacheEncoder`.
-}
maybeHighlightedCommentCacheEncoder : MaybeHighlightedComment -> Encode.Value
maybeHighlightedCommentCacheEncoder maybeHighlightedComment =
    Encode.object
        [ ( "range"
          , Util.justValueOrNull
                Range.rangeCacheEncoder
                maybeHighlightedComment.range
          )
        , ( "comment"
          , Util.justValueOrNull
                Encode.string
                maybeHighlightedComment.comment
          )
        ]


{-| MaybeHighlightedComment `cacheDecoder`.
-}
maybeHighlightedCommentCacheDecoder : Decode.Decoder MaybeHighlightedComment
maybeHighlightedCommentCacheDecoder =
    Decode.map2 MaybeHighlightedComment
        (Decode.field "range" (Decode.maybe Range.rangeCacheDecoder))
        (Decode.field "comment" (Decode.maybe Decode.string))
