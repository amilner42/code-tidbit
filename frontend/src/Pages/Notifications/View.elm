module Pages.Notifications.View exposing (..)

import Date.Format
import DefaultServices.Util as Util
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Notification exposing (Notification)
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.Notifications.Messages exposing (..)
import Pages.Notifications.Model exposing (..)


{-| `Notifications` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "notifications-page" ]
        [ case model.notifications of
            Nothing ->
                Util.hiddenDiv

            Just ( isMoreNotifications, notifications ) ->
                div
                    [ class "notificatons-list" ]
                    [ div [ class "title" ] [ text "All Notifications" ]
                    , div [ class "list" ] <|
                        List.map
                            (\notification ->
                                notificationView
                                    (RT.isMakingRequest shared.apiRequestTracker <|
                                        RT.SetNotificationRead notification.id
                                    )
                                    notification
                            )
                            notifications
                    , if isMoreNotifications then
                        div
                            [ classList
                                [ ( "load-more-notifications", True )
                                , ( "cursor-progress", RT.isMakingRequest shared.apiRequestTracker RT.GetNotifications )
                                ]
                            , onClick <| LoadMoreNotifications notifications
                            ]
                            [ text "load more" ]
                      else
                        div
                            [ class "no-more-notifications" ]
                            [ text <|
                                if List.isEmpty notifications then
                                    "no notifications yet"
                                else
                                    "no more notifications"
                            ]
                    ]
        ]


{-| The view for rendering a single `Notification`.
-}
notificationView : Bool -> Notification -> Html Msg
notificationView isMakingSetNotificationReadRequest notification =
    div
        [ class "notification" ]
        [ div [ class "message" ] [ text notification.message ]
        , div
            [ class "bottom-bar" ]
            [ Route.navigationNode
                (Just
                    ( Route.Link <| Tuple.second notification.actionLink
                    , GoToNotificationLink notification.id notification.read <| Tuple.second notification.actionLink
                    )
                )
                []
                [ button
                    []
                    [ text <| Tuple.first notification.actionLink ]
                ]
            , button
                [ classList
                    [ ( "toggle-read", True )
                    , ( "is-read", notification.read )
                    , ( "cursor-progress", isMakingSetNotificationReadRequest )
                    ]
                , onClick <| SetNotificationRead notification.id (not notification.read)
                ]
                [ text <|
                    if notification.read then
                        "seen"
                    else
                        "mark as seen"
                ]
            , div
                [ class "created-date" ]
                [ text <| Date.Format.format "%m/%d/%Y" notification.createdAt ]
            ]
        ]
