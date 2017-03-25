module Pages.DevelopStory.Update exposing (..)

import Api
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Route as Route
import Models.Tidbit as Tidbit
import Pages.DevelopStory.Messages exposing (..)
import Pages.DevelopStory.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `DevelopStory` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )

        justSetShared newShared =
            ( model, newShared, Cmd.none )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )
    in
        case msg of
            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                case route of
                    Route.DevelopStoryPage storyID ->
                        (if
                            maybeMapWithDefault
                                (.id >> ((==) storyID))
                                False
                                model.currentStory
                         then
                            doNothing
                         else
                            ( { model
                                | currentStory = Nothing
                                , tidbitsToAdd = []
                              }
                            , shared
                            , Api.getExpandedStory
                                storyID
                                CreateStoryGetStoryFailure
                                (CreateStoryGetStorySuccess False)
                            )
                        )
                            |> withCmd
                                (Cmd.batch
                                    [ case ( Util.isNothing shared.userTidbits, shared.user ) of
                                        ( True, Just user ) ->
                                            Api.getTidbits
                                                [ ( "forUser", Just user.id ) ]
                                                CreateStoryGetTidbitsFailure
                                                CreateStoryGetTidbitsSuccess

                                        _ ->
                                            Cmd.none
                                    , Ports.doScrolling
                                        { querySelector = "#story-tidbits-title"
                                        , duration = 500
                                        , extraScroll = -60
                                        }
                                    ]
                                )

                    _ ->
                        doNothing

            CreateStoryGetStoryFailure apiError ->
                -- TODO handle error
                doNothing

            CreateStoryGetStorySuccess resetUserStories expandedStory ->
                let
                    -- Resets stories if needed.
                    newShared =
                        if resetUserStories then
                            { shared
                                | userStories = Nothing
                            }
                        else
                            shared
                in
                    case shared.user of
                        -- Should never happen.
                        Nothing ->
                            doNothing

                        Just user ->
                            -- If this is indeed the author, then stay on page,
                            -- otherwise redirect.
                            if user.id == expandedStory.author then
                                ( setCurrentStory expandedStory model
                                , newShared
                                , Cmd.none
                                )
                            else
                                ( model
                                , newShared
                                , Route.modifyTo Route.CreatePage
                                )

            CreateStoryGetTidbitsFailure apiError ->
                -- Handle error.
                doNothing

            CreateStoryGetTidbitsSuccess tidbits ->
                justSetShared
                    { shared
                        | userTidbits = Just tidbits
                    }

            CreateStoryAddTidbit tidbit ->
                justUpdateModel <| addTidbit tidbit

            CreateStoryRemoveTidbit tidbit ->
                justUpdateModel <| removeTidbit tidbit

            CreateStoryPublishAddedTidbits storyID tidbits ->
                if List.length tidbits > 0 then
                    justProduceCmd <|
                        Api.postAddTidbitsToStory
                            storyID
                            (List.map Tidbit.compressTidbit tidbits)
                            CreateStoryPublishAddedTidbitsFailure
                            (CreateStoryGetStorySuccess True)
                else
                    -- Should never happen.
                    doNothing

            CreateStoryPublishAddedTidbitsFailure apiError ->
                -- TODO handle error.
                doNothing
