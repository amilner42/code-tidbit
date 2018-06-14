module Pages.DevelopStory.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..))
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Tidbit as Tidbit
import Pages.DevelopStory.Messages exposing (..)
import Pages.DevelopStory.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Ports


{-| `DevelopStory` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
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
                            if maybeMapWithDefault (.id >> (==) storyID) False model.story then
                                model.tidbitsToAdd
                            else
                                []
                      }
                    , shared
                    , Cmd.batch
                        [ common.api.get.expandedStory
                            storyID
                            (common.subMsg << OnGetStoryFailure)
                            (common.subMsg << OnGetStorySuccess)
                        , maybeMapWithDefault
                            (\{ id } ->
                                if Util.isNothing shared.userTidbits then
                                    common.api.get.tidbits
                                        [ ( "author", Just id ) ]
                                        (common.subMsg << OnGetTidbitsFailure)
                                        (common.subMsg << OnGetTidbitsSuccess << Tuple.second)
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
                    common.doNothing

        OnGetStorySuccess expandedStory ->
            maybeMapWithDefault
                (\{ id } ->
                    -- If this is indeed the author, then stay on page, otherwise redirect.
                    if id == expandedStory.author then
                        common.justUpdateModel <| setStory expandedStory
                    else
                        common.justProduceCmd <| Route.modifyTo Route.CreatePage
                )
                common.doNothing
                shared.user

        OnGetStoryFailure apiError ->
            common.justSetModalError apiError

        OnGetTidbitsSuccess tidbits ->
            common.justSetShared { shared | userTidbits = Just tidbits }

        OnGetTidbitsFailure apiError ->
            -- Handle error.
            common.doNothing

        AddTidbit tidbit ->
            common.justUpdateModel <| addTidbit tidbit

        RemoveTidbit tidbit ->
            common.justUpdateModel <| removeTidbit tidbit

        PublishAddedTidbits storyID tidbits ->
            let
                publishAction =
                    common.justProduceCmd <|
                        common.api.post.addTidbitsToStory
                            storyID
                            (List.map Tidbit.compressTidbit tidbits)
                            (common.subMsg << OnPublishAddedTidbitsFailure)
                            (common.subMsg << OnPublishAddedTidbitsSuccess)
            in
            if List.length tidbits > 0 then
                common.makeSingletonRequest RT.PublishNewTidbitsToStory publishAction
            else
                -- Should never happen.
                common.doNothing

        OnPublishAddedTidbitsSuccess expandedStory ->
            ( { model
                | story = Just expandedStory
                , tidbitsToAdd = []
              }
            , { shared | userStories = Nothing }
            , Cmd.none
            )
                |> common.andFinishRequest RT.PublishNewTidbitsToStory

        OnPublishAddedTidbitsFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.PublishNewTidbitsToStory
