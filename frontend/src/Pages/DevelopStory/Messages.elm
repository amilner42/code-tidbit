module Pages.DevelopStory.Messages exposing (..)

import Models.ApiError as ApiError
import Models.Story as Story
import Models.Tidbit as Tidbit
import Models.Route as Route


{-| `DevelopStory` msg.
-}
type Msg
    = GoTo Route.Route
    | OnRouteHit Route.Route
    | CreateStoryGetStoryFailure ApiError.ApiError
    | CreateStoryGetStorySuccess Bool Story.ExpandedStory
    | CreateStoryGetTidbitsFailure ApiError.ApiError
    | CreateStoryGetTidbitsSuccess (List Tidbit.Tidbit)
    | CreateStoryAddTidbit Tidbit.Tidbit
    | CreateStoryRemoveTidbit Tidbit.Tidbit
    | CreateStoryPublishAddedTidbits String (List Tidbit.Tidbit)
    | CreateStoryPublishAddedTidbitsFailure ApiError.ApiError
