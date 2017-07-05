module Pages.Notifications.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Notification exposing (Notification)
import Models.Route exposing (Route)


{-| `Notifications` Msg.
-}
type Msg
    = NoOp
    | GoTo Route
    | OnRouteHit Route
    | OnGetNotificationsFailure ApiError
    | OnGetNotificationsSuccess ( Bool, List Notification )
