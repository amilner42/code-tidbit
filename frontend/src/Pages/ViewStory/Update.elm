module Pages.ViewStory.Update exposing (..)

import Api
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (..)
import Ports


{-| `ViewStory` update.
-}
update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    let
        api =
            Api.api shared.flags.apiBaseUrl

        doNothing =
            ( shared, Cmd.none )

        justSetShared newShared =
            ( newShared, Cmd.none )

        justProduceCmd newCmd =
            ( shared, newCmd )
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                case route of
                    -- We always grab the latest story because this can be edited outside of the users control.
                    Route.ViewStoryPage mongoID ->
                        ( { shared | viewingStory = Nothing }
                        , Cmd.batch
                            [ Ports.smoothScrollToSubBar
                            , api.get.expandedStoryWithCompleted
                                mongoID
                                OnGetExpandedStoryFailure
                                OnGetExpandedStorySuccess
                            ]
                        )

                    _ ->
                        doNothing

            OnGetExpandedStorySuccess expandedStory ->
                justSetShared <| { shared | viewingStory = Just expandedStory }

            OnGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing
