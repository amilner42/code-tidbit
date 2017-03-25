module Models.Snipbit exposing (..)

import Array
import Date
import Elements.Editor as Editor exposing (Language)
import Models.HighlightedComment exposing (HighlightedComment)


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
