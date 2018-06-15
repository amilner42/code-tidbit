module Pages.ViewStory.Update exposing (..)

import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import Models.ContentPointer as ContentPointer
import Models.Opinion exposing (PossibleOpinion, toPossibleOpinion)
import Models.RequestTracker as RT
import Models.Route as Route
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (..)
import Pages.ViewStory.Model exposing (..)
import Ports


{-| `ViewStory` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    case msg of
        OnRouteHit route ->
            case route of
                {- We:
                   - always grab the latest story because this can be edited outside of the users control.
                   - may need to fetch the users opinion on the story if it's not cached (browser-level).
                -}
                Route.ViewStoryPage mongoID ->
                    let
                        -- Fetches the story.
                        getStory (Common common) ( model, shared ) =
                            ( model
                            , { shared | viewingStory = Nothing }
                            , Cmd.batch
                                [ Ports.smoothScrollToSubBar
                                , common.api.get.expandedStoryWithCompleted
                                    mongoID
                                    (common.subMsg << OnGetExpandedStoryFailure)
                                    (common.subMsg << OnGetExpandedStorySuccess)
                                ]
                            )

                        -- Fetch's the opinion if needed.
                        getOpinion (Common common) ( model, shared ) =
                            let
                                contentPointer =
                                    { contentType = ContentPointer.Story
                                    , contentID = mongoID
                                    }

                                getOpinion =
                                    ( { model | possibleOpinion = Nothing }
                                    , shared
                                    , common.api.get.opinion
                                        contentPointer
                                        (common.subMsg << OnGetOpinionFailure)
                                        (common.subMsg << OnGetOpinionSuccess << PossibleOpinion contentPointer)
                                    )
                            in
                            case ( shared.user, model.possibleOpinion ) of
                                ( Just user, Just { contentPointer, rating } ) ->
                                    if contentPointer.contentID == mongoID then
                                        common.doNothing
                                    else
                                        getOpinion

                                ( Just user, Nothing ) ->
                                    getOpinion

                                _ ->
                                    common.doNothing
                    in
                    common.handleAll
                        [ getStory
                        , getOpinion
                        ]

                _ ->
                    common.doNothing

        OnGetExpandedStorySuccess expandedStory ->
            common.justSetShared <| { shared | viewingStory = Just expandedStory }

        OnGetExpandedStoryFailure apiError ->
            common.justSetModalError apiError

        OnGetOpinionSuccess possibleOpinion ->
            common.justSetModel { model | possibleOpinion = Just possibleOpinion }

        OnGetOpinionFailure apiError ->
            common.justSetModalError apiError

        AddOpinion opinion ->
            let
                addOpinionAction =
                    common.justProduceCmd <|
                        common.api.post.addOpinion
                            opinion
                            (common.subMsg << OnAddOpinionFailure)
                            (always <| common.subMsg <| OnAddOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Story) addOpinionAction

        OnAddOpinionSuccess opinion ->
            common.justSetModel { model | possibleOpinion = Just <| toPossibleOpinion opinion }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Story)

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Story)

        RemoveOpinion opinion ->
            let
                removeOpinionAction =
                    common.justProduceCmd <|
                        common.api.post.removeOpinion
                            opinion
                            (common.subMsg << OnRemoveOpinionFailure)
                            (always <| common.subMsg <| OnRemoveOpinionSuccess opinion)
            in
            common.makeSingletonRequest (RT.AddOrRemoveOpinion ContentPointer.Story) removeOpinionAction

        OnRemoveOpinionSuccess { contentPointer } ->
            common.justSetModel
                { model
                    | possibleOpinion = Just { contentPointer = contentPointer, rating = Nothing }
                }
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Story)

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest (RT.AddOrRemoveOpinion ContentPointer.Story)
