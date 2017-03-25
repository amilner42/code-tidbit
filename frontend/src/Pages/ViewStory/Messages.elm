module Pages.ViewStory.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)


{-| `ViewStory` msg.
-}
type Msg
    = GoTo Route
    | OnRouteHit Route
    | GetExpandedStoryFailure ApiError
    | GetExpandedStorySuccess ExpandedStory
