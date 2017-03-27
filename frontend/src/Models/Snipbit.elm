module Models.Snipbit exposing (..)

import Array
import Date
import Elements.Editor as Editor exposing (Language)
import Models.Range exposing (Range)


{-| A snipbit as seen in the db.
-}
type alias Snipbit =
    { id : String
    , language : Language
    , name : String
    , description : String
    , tags : List String
    , code : String
    , introduction : String
    , conclusion : String
    , highlightedComments : Array.Array HighlightedComment
    , author : String
    , createdAt : Date.Date
    , lastModified : Date.Date
    }


{-| A highlighted comment used in published snipbits.
-}
type alias HighlightedComment =
    { range : Range
    , comment : String
    }


{-| A maybe highlighted comment, currently used for the creation of highlighted
comments in snipbits.
-}
type alias MaybeHighlightedComment =
    { range : Maybe Range
    , comment : Maybe String
    }
