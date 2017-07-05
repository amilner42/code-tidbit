module Pages.Notifications.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.Notifications.Messages exposing (..)
import Pages.Notifications.Model exposing (..)


{-| `Notifications` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update (Common common) msg model shared =
    case msg of
        NoOp ->
            common.doNothing

        GoTo route ->
            common.justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                Route.NotificationsPage ->
                    if Util.isNotNothing shared.user then
                        common.makeSingletonRequest RT.GetNotifications <|
                            common.justProduceCmd <|
                                common.api.get.notifications OnGetNotificationsFailure OnGetNotificationsSuccess
                    else
                        common.doNothing

                _ ->
                    common.doNothing

        OnGetNotificationsFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.GetNotifications

        OnGetNotificationsSuccess notifications ->
            common.justSetModel { model | notifications = Just notifications }
                |> common.andFinishRequest RT.GetNotifications
