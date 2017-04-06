module Pages.DevelopStory.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)
import Models.Tidbit exposing (Tidbit)


{-| `DevelopStory` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetStorySuccess ExpandedStory
    | OnGetStoryFailure ApiError
    | OnGetTidbitsSuccess (List Tidbit)
    | OnGetTidbitsFailure ApiError
    | AddTidbit Tidbit
    | RemoveTidbit Tidbit
    | PublishAddedTidbits String (List Tidbit)
    | OnPublishAddedTidbitsSuccess ExpandedStory
    | OnPublishAddedTidbitsFailure ApiError
