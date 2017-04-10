module Pages.Browse.Model exposing (..)

import Models.Content exposing (Content)


{-| `Browse` model.
-}
type alias Model =
    { content : Maybe (List Content)
    , pageNumber : Int
    , noMoreContent : Bool
    , searchQuery : String
    , showNewContentMessage : Bool
    , showAdvancedSearchOptions : Bool
    , contentFilterSnipbits : Bool
    , contentFilterBigbits : Bool
    , contentFilterStories : Bool
    , contentFilterIncludeEmptyStories : Bool
    }
