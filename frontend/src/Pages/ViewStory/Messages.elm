module Pages.ViewStory.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Opinion exposing (Opinion, PossibleOpinion)
import Models.Route exposing (Route)
import Models.Story exposing (ExpandedStory)


{-| `ViewStory` msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetOpinionSuccess PossibleOpinion
    | OnGetOpinionFailure ApiError
    | AddOpinion Opinion
    | OnAddOpinionSuccess Opinion
    | OnAddOpinionFailure ApiError
    | RemoveOpinion Opinion
    | OnRemoveOpinionSuccess Opinion
    | OnRemoveOpinionFailure ApiError
    | OnGetExpandedStorySuccess ExpandedStory
    | OnGetExpandedStoryFailure ApiError
    | SetUserNeedsAuthModal String -- TODO delete
