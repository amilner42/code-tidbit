module Pages.Browse.Messages exposing (..)

import Elements.Simple.Editor exposing (Language)
import Models.ApiError exposing (ApiError)
import Models.Content exposing (Content)
import Models.Route exposing (Route)


{-| Browse `Msg`
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetContentSuccess (List Content)
    | OnGetContentFailure ApiError
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
