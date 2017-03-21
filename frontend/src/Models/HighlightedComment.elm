module Models.HighlightedComment exposing (..)

import Models.Range as Range


{-| A highlighted comment used in published snipbits.
-}
type alias HighlightedComment =
    { range : Range.Range
    , comment : String
    }


{-| A maybe highlighted comment, currently used for the creation of highlighted
comments in snipbits.
-}
type alias MaybeHighlightedComment =
    { range : Maybe Range.Range
    , comment : Maybe String
    }
