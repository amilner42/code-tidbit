module Pages.Browse.Model exposing (..)

import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
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
    , mostRecentSearchSettings : Maybe SearchSettings
    }


{-| All the options for customizing the search settings.
-}
type alias SearchSettings =
    { includeSnipbits : Bool
    , includeBigbits : Bool
    , includeStories : Bool
    , includeEmptyStories : Bool
    , restrictLanguage : Maybe String
    , author : Maybe String
    , searchQuery : Maybe String
    , pageNumber : Int
    }


{-| Extracts the search settings from the model.
-}
extractSearchSettingsFromModel : Model -> SearchSettings
extractSearchSettingsFromModel model =
    { includeSnipbits = model.contentFilterSnipbits
    , includeBigbits = model.contentFilterBigbits
    , includeStories = model.contentFilterStories
    , includeEmptyStories = model.contentFilterIncludeEmptyStories
    , restrictLanguage = model.contentFilterLanguage ||> toString
    , author = model.contentFilterAuthor |> Tuple.second
    , searchQuery = Util.justNonBlankString model.searchQuery
    , pageNumber = model.pageNumber
    }
