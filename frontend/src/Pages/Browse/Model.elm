module Pages.Browse.Model exposing (..)

import Elements.Simple.Editor exposing (Language)
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
    , contentFilterLanguage : Maybe Language
    , contentFilterAuthor : ( String, Maybe String )
    }
