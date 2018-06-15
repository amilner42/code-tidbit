module Pages.Notifications.Messages exposing (..)

import Models.ApiError exposing (ApiError)
import Models.Notification exposing (Notification)
import Models.Route exposing (Route)
import ProjectTypeAliases exposing (..)


{-| `Notifications` Msg.
-}
type Msg
    = GoToNotificationLink NotificationID Bool Link
    | OnRouteHit Route
    | OnGetInitialNotificationsFailure ApiError
    | OnGetInitialNotificationsSuccess ( Bool, List Notification )
    | SetNotificationRead NotificationID Bool
    | OnSetNotificationReadFailure NotificationID ApiError
    | OnSetNotificationReadSuccess NotificationID Bool
    | LoadMoreNotifications (List Notification)
    | OnLoadMoreNotificationsFailure ApiError
    | OnLoadMoreNotificationsSuccess (List Notification) ( Bool, List Notification )
