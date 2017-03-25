module Pages.ViewStory.Update exposing (..)

import Api
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (Msg(..))
import Ports


{-| `ViewStory` update.
-}
update : Msg -> Shared -> ( Shared, Cmd Msg )
update msg shared =
    let
        doNothing =
            ( shared, Cmd.none )

        justSetShared newShared =
            ( newShared, Cmd.none )

        justProduceCmd newCmd =
            ( shared, newCmd )
    in
        case msg of
            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                case route of
                    Route.ViewStoryPage mongoID ->
                        ( { shared
                            | viewingStory = Nothing
                          }
                        , Cmd.batch
                            [ Ports.smoothScrollToSubBar
                            , Api.getExpandedStoryWithCompleted
                                mongoID
                                ViewStoryGetExpandedStoryFailure
                                ViewStoryGetExpandedStorySuccess
                            ]
                        )

                    _ ->
                        doNothing

            ViewStoryGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewStoryGetExpandedStorySuccess expandedStory ->
                justSetShared <|
                    { shared
                        | viewingStory = Just expandedStory
                    }
