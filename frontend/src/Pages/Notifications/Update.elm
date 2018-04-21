module Pages.Notifications.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.Util as Util
import List.Extra
import Models.RequestTracker as RT
import Models.Route as Route
import Navigation exposing (newUrl)
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

        GoToNotificationLink notificationID read link ->
            common.handleAll
                [ \(Common common) ( model, shared ) -> common.justProduceCmd <| newUrl link
                , \(Common common) ( model, shared ) ->
                    if read then
                        common.doNothing
                    else
                        common.makeSingletonRequest (RT.SetNotificationRead notificationID) <|
                            common.justProduceCmd <|
                                common.api.post.setNotificationRead
                                    notificationID
                                    True
                                    (OnSetNotificationReadFailure notificationID)
                                    (always <| OnSetNotificationReadSuccess notificationID True)
                ]

        OnRouteHit route ->
            case route of
                Route.NotificationsPage ->
                    if Util.isNotNothing shared.user then
                        common.makeSingletonRequest RT.GetNotifications <|
                            common.justProduceCmd <|
                                common.api.get.notifications
                                    []
                                    OnGetInitialNotificationsFailure
                                    OnGetInitialNotificationsSuccess
                    else
                        common.doNothing

                _ ->
                    common.doNothing

        OnGetInitialNotificationsFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.GetNotifications

        OnGetInitialNotificationsSuccess notifications ->
            common.justSetModel
                { model
                    | notifications = Just notifications
                    , pageNumber = 2
                }
                |> common.andFinishRequest RT.GetNotifications

        SetNotificationRead notificationID read ->
            common.makeSingletonRequest (RT.SetNotificationRead notificationID) <|
                common.justProduceCmd <|
                    common.api.post.setNotificationRead
                        notificationID
                        read
                        (OnSetNotificationReadFailure notificationID)
                        (always <| OnSetNotificationReadSuccess notificationID read)

        OnSetNotificationReadFailure notificationID apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.SetNotificationRead notificationID)

        OnSetNotificationReadSuccess notificationID read ->
            common.justSetModel
                { model
                    | notifications =
                        model.notifications
                            ||> (\( isMoreNotifications, notifications ) ->
                                    ( isMoreNotifications
                                    , notifications
                                        |> List.Extra.updateIf
                                            (.id >> (==) notificationID)
                                            (\notification -> { notification | read = read })
                                    )
                                )
                }
                |> common.andFinishRequest (RT.SetNotificationRead notificationID)

        LoadMoreNotifications currentNotifications ->
            common.makeSingletonRequest RT.GetNotifications <|
                common.justProduceCmd <|
                    common.api.get.notifications
                        [ ( "pageNumber", Just <| toString model.pageNumber ) ]
                        OnLoadMoreNotificationsFailure
                        (OnLoadMoreNotificationsSuccess currentNotifications)

        OnLoadMoreNotificationsFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.GetNotifications

        OnLoadMoreNotificationsSuccess currentNotifications ( isMoreNotifications, notifications ) ->
            common.justSetModel
                { model
                    | notifications = Just ( isMoreNotifications, currentNotifications ++ notifications )
                    , pageNumber = model.pageNumber + 1
                }
                |> common.andFinishRequest RT.GetNotifications
