module Pages.ViewStory.Messages exposing (..)

import Models.ApiError as ApiError
import Models.Story as Story
import Models.Route as Route


{-| `ViewStory` msg.
-}
type Msg
    = GoTo Route.Route
    | OnRouteHit Route.Route
    | ViewStoryGetExpandedStoryFailure ApiError.ApiError
    | ViewStoryGetExpandedStorySuccess Story.ExpandedStory
