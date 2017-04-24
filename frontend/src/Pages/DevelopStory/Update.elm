module Pages.DevelopStory.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.Route as Route
import Models.Tidbit as Tidbit
import Pages.DevelopStory.Messages exposing (..)
import Pages.DevelopStory.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `DevelopStory` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update ({ doNothing, justSetShared, justSetModel, justUpdateModel, justProduceCmd, api } as common) msg model shared =
    case msg of
        NoOp ->
            doNothing

        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                {- We cache the `model.story` in localStorage so that we can see if we can keep the
                   `model.tidbitsToAdd`, but because we cache it in localStorage we always re-query to get the story to
                   make sure we have the newest copy. When updating to the newest copy of a story we can still keep the
                   `model.tidbitsToAdd` (that's the whole point).

                   The user's tidbits are not cached in localStorage so it's per-session, we don't need to update them
                   if we already have them.
                -}
                Route.DevelopStoryPage storyID ->
                    ( { model
                        | story = Nothing
                        , tidbitsToAdd =
                            if maybeMapWithDefault (.id >> ((==) storyID)) False model.story then
                                model.tidbitsToAdd
                            else
                                []
                      }
                    , shared
                    , Cmd.batch
                        [ api.get.expandedStory storyID OnGetStoryFailure OnGetStorySuccess
                        , maybeMapWithDefault
                            (\{ id } ->
                                if Util.isNothing shared.userTidbits then
                                    api.get.tidbits [ ( "author", Just id ) ] OnGetTidbitsFailure OnGetTidbitsSuccess
                                else
                                    Cmd.none
                            )
                            Cmd.none
                            shared.user
                        , Ports.doScrolling
                            { querySelector = "#story-tidbits-title", duration = 500, extraScroll = -60 }
                        ]
                    )

                _ ->
                    doNothing

        OnGetStorySuccess expandedStory ->
            maybeMapWithDefault
                (\{ id } ->
                    -- If this is indeed the author, then stay on page, otherwise redirect.
                    if id == expandedStory.author then
                        justUpdateModel <| setStory expandedStory
                    else
                        justProduceCmd <| Route.modifyTo Route.CreatePage
                )
                doNothing
                shared.user

        OnGetStoryFailure apiError ->
            common.justSetModalError apiError

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
                    api.post.addTidbitsToStory
                        storyID
                        (List.map Tidbit.compressTidbit tidbits)
                        OnPublishAddedTidbitsFailure
                        OnPublishAddedTidbitsSuccess
            else
                -- Should never happen.
                doNothing

        OnPublishAddedTidbitsSuccess expandedStory ->
            ( { model
                | story = Just expandedStory
                , tidbitsToAdd = []
              }
            , { shared | userStories = Nothing }
            , Cmd.none
            )

        OnPublishAddedTidbitsFailure apiError ->
            common.justSetModalError apiError
