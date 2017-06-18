module Models.Vote exposing (..)

{-| -}


{-| For users placing opinions.

Differs from `Rating` in the options, currently `Rating` can only be positive. `Vote` can be positive and negative.

NOTE: Parralels to the `Vote` enum on the backend.

-}
type Vote
    = Upvote
    | Downvote
