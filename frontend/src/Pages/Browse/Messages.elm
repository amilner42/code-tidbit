module Pages.Browse.Messages exposing (..)

import Elements.Simple.Editor exposing (Language)
import Models.ApiError exposing (ApiError)
import Models.Content exposing (Content)
import Models.Route exposing (Route)
import Pages.Browse.Model exposing (..)


{-| Browse `Msg`
-}
type Msg
    = NoOp
    | OnRouteHit Route
    | OnGetContentSuccess SearchSettings ( Bool, List Content )
    | OnGetContentFailure SearchSettings ApiError
    | LoadMoreContent
    | OnUpdateSearch String
    | Search
    | ToggleAdvancedOptions
    | ToggleContentFilterSnipbits
    | ToggleContentFilterBigbits
    | ToggleContentFilterStories
    | SetIncludeEmptyStories Bool
    | SelectLanguage (Maybe Language)
    | OnUpdateContentFilterAuthor String
    | OnGetUserExistsFailure ApiError
    | OnGetUserExistsSuccess ( String, Maybe String )
