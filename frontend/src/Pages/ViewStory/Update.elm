module Pages.ViewStory.Update exposing (..)

import Api
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil, commonSubPageUtil)
import Models.ContentPointer as ContentPointer
import Models.Opinion exposing (toPossibleOpinion)
import Models.Route as Route
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (..)
import Pages.ViewStory.Model exposing (..)
import Ports


{-| `ViewStory` update.
-}
update : CommonSubPageUtil Model Shared Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update ({ doNothing, justSetModel, justProduceCmd, justSetShared, justSetModalError, api } as common) msg model shared =
    case msg of
        NoOp ->
            doNothing

        GoTo route ->
            justProduceCmd <| Route.navigateTo route

        OnRouteHit route ->
            case route of
                {- We:
                   - always grab the latest story because this can be edited outside of the users control.
                   - may need to fetch the users opinion on the story if it's not cached (browser-level).
                -}
                Route.ViewStoryPage mongoID ->
                    let
                        -- Fetches the story.
                        getStory ( model, shared ) =
                            ( model
                            , { shared | viewingStory = Nothing }
                            , Cmd.batch
                                [ Ports.smoothScrollToSubBar
                                , api.get.expandedStoryWithCompleted
                                    mongoID
                                    OnGetExpandedStoryFailure
                                    OnGetExpandedStorySuccess
                                ]
                            )

                        -- Fetch's the opinion if needed.
                        getOpinion ( model, shared ) =
                            let
                                { doNothing } =
                                    commonSubPageUtil model shared

                                contentPointer =
                                    { contentType = ContentPointer.Story
                                    , contentID = mongoID
                                    }

                                getOpinion =
                                    ( { model | possibleOpinion = Nothing }
                                    , shared
                                    , api.get.opinionWrapper
                                        contentPointer
                                        OnGetOpinionFailure
                                        OnGetOpinionSuccess
                                    )
                            in
                                case ( shared.user, model.possibleOpinion ) of
                                    ( Just user, Just { contentPointer, rating } ) ->
                                        if contentPointer.contentID == mongoID then
                                            doNothing
                                        else
                                            getOpinion

                                    ( Just user, Nothing ) ->
                                        getOpinion

                                    _ ->
                                        doNothing
                    in
                        common.handleAll
                            [ getStory
                            , getOpinion
                            ]

                _ ->
                    doNothing

        OnGetExpandedStorySuccess expandedStory ->
            justSetShared <| { shared | viewingStory = Just expandedStory }

        OnGetExpandedStoryFailure apiError ->
            justSetModalError apiError

        OnGetOpinionSuccess possibleOpinion ->
            justSetModel { model | possibleOpinion = Just possibleOpinion }

        OnGetOpinionFailure apiError ->
            common.justSetModalError apiError

        AddOpinion opinion ->
            justProduceCmd <|
                api.post.addOpinionWrapper opinion OnAddOpinionFailure OnAddOpinionSuccess

        OnAddOpinionSuccess opinion ->
            justSetModel { model | possibleOpinion = Just <| toPossibleOpinion opinion }

        OnAddOpinionFailure apiError ->
            common.justSetModalError apiError

        RemoveOpinion opinion ->
            justProduceCmd <|
                api.post.removeOpinionWrapper opinion OnRemoveOpinionFailure OnRemoveOpinionSuccess

        OnRemoveOpinionSuccess { contentPointer } ->
            justSetModel
                { model
                    | possibleOpinion = Just { contentPointer = contentPointer, rating = Nothing }
                }

        OnRemoveOpinionFailure apiError ->
            common.justSetModalError apiError
