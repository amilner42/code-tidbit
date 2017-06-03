module JSON.Vote exposing (..)

import Json.Encode as Encode
import Models.Vote exposing (..)


{-| `Vote` encoder.
-}
encoder : Vote -> Encode.Value
encoder vote =
    Encode.int <|
        case vote of
            Upvote ->
                1

            Downvote ->
                2
