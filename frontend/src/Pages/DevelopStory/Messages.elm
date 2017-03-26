module Pages.DevelopStory.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)
import Models.Tidbit exposing (Tidbit)


{-| `DevelopStory` msg.
-}
type Msg
    = GoTo Route
    | OnRouteHit Route
    | OnGetStorySuccess Bool ExpandedStory
    | OnGetStoryFailure ApiError
    | OnGetTidbitsSuccess (List Tidbit)
    | OnGetTidbitsFailure ApiError
    | AddTidbit Tidbit
    | RemoveTidbit Tidbit
    | PublishAddedTidbits String (List Tidbit)
    | OnPublishAddedTidbitsFailure ApiError
