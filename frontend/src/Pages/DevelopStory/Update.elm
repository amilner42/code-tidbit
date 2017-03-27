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
                        (if maybeMapWithDefault (.id >> ((==) storyID)) False model.story then
                            doNothing
                         else
                            ( { model
                                | story = Nothing
                                , tidbitsToAdd = []
                              }
                            , shared
                            , Api.getExpandedStory storyID OnGetStoryFailure (OnGetStorySuccess False)
                            )
                        )
                            |> withCmd
                                (Cmd.batch
                                    [ case ( Util.isNothing shared.userTidbits, shared.user ) of
                                        ( True, Just user ) ->
                                            Api.getTidbits
                                                [ ( "forUser", Just user.id ) ]
                                                OnGetTidbitsFailure
                                                OnGetTidbitsSuccess

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

            OnGetStorySuccess resetUserStories expandedStory ->
                let
                    -- Resets stories if needed.
                    newShared =
                        if resetUserStories then
                            { shared | userStories = Nothing }
                        else
                            shared
                in
                    case shared.user of
                        -- Should never happen.
                        Nothing ->
                            doNothing

                        Just user ->
                            -- If this is indeed the author, then stay on page, otherwise redirect.
                            if user.id == expandedStory.author then
                                ( setStory expandedStory model
                                , newShared
                                , Cmd.none
                                )
                            else
                                ( model
                                , newShared
                                , Route.modifyTo Route.CreatePage
                                )

            OnGetStoryFailure apiError ->
                -- TODO handle error
                doNothing

            OnGetTidbitsSuccess tidbits ->
                justSetShared { shared | userTidbits = Just tidbits }

            OnGetTidbitsFailure apiError ->
                -- Handle error.
                doNothing

            AddTidbit tidbit ->
                justUpdateModel <| addTidbit tidbit

            RemoveTidbit tidbit ->
                justUpdateModel <| removeTidbit tidbit

            PublishAddedTidbits storyID tidbits ->
                if List.length tidbits > 0 then
                    justProduceCmd <|
                        Api.postAddTidbitsToStory
                            storyID
                            (List.map Tidbit.compressTidbit tidbits)
                            OnPublishAddedTidbitsFailure
                            (OnGetStorySuccess True)
                else
                    -- Should never happen.
                    doNothing

            OnPublishAddedTidbitsFailure apiError ->
                -- TODO handle error.
                doNothing
