module Pages.Browse.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Content exposing (Content)
import Models.Route exposing (Route)


{-| Browse `Msg`
-}
type Msg
    = NoOp
    | OnRouteHit Route
    | OnGetContentSuccess (List Content)
    | OnGetContentFailure ApiError
    | LoadMoreContent
