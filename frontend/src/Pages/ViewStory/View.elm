module Pages.ViewStory.View exposing (..)

import DefaultServices.Util as Util
import Elements.Simple.ContentBox as ContentBox
import Elements.Simple.ProgressBar as ProgressBar exposing (State(..), TextFormat(Percentage))
import ExplanatoryBlurbs
import Html exposing (Html, button, div, i, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Content as Content
import Models.ContentPointer as ContentPointer
import Models.Rating as Rating
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Story as Story
import Models.Tidbit as Tidbit
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (..)
import Pages.ViewStory.Model exposing (..)


{-| `ViewStory` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    case shared.viewingStory of
        Nothing ->
            Util.hiddenDiv

        Just story ->
            let
                completedListForLoggedInUser : Maybe (List Bool)
                completedListForLoggedInUser =
                    case ( shared.user, shared.viewingStory |> Maybe.andThen .userHasCompleted ) of
                        ( Just user, Just hasCompletedList ) ->
                            Just hasCompletedList

                        _ ->
                            Nothing

                nextTidbitInStory : Maybe ( Int, Route.Route )
                nextTidbitInStory =
                    completedListForLoggedInUser
                        |> Maybe.andThen Util.indexOfFirstFalse
                        |> Maybe.andThen
                            (\index ->
                                Util.getAt story.tidbits index
                                    |> Maybe.map (Tidbit.getTidbitRoute (Just story.id) >> (,) index)
                            )
            in
            div
                [ class "view-story-page" ]
                [ Util.keyedDiv
                    [ class "sub-bar" ]
                    [ ( "view-story-next-tidbit-button"
                      , case nextTidbitInStory of
                            Just ( index, routeForViewingTidbit ) ->
                                Route.navigationNode
                                    (Just
                                        ( Route.Route routeForViewingTidbit
                                        , BaseMessage.GoTo { wipeModalError = False } routeForViewingTidbit
                                        )
                                    )
                                    []
                                    [ button
                                        [ class "sub-bar-button next-tidbit-button" ]
                                        [ text <| "Continue on Tidbit " ++ (toString <| index + 1) ]
                                    ]

                            _ ->
                                Util.hiddenDiv
                      )
                    , ( "view-story-opinions-button"
                      , case ( shared.user, model.possibleOpinion ) of
                            ( Just _, Just possibleOpinion ) ->
                                let
                                    ( newMsg, buttonText ) =
                                        case possibleOpinion.rating of
                                            Nothing ->
                                                ( AddOpinion
                                                    { contentPointer = possibleOpinion.contentPointer
                                                    , rating = Rating.Like
                                                    }
                                                , "Love It"
                                                )

                                            Just rating ->
                                                ( RemoveOpinion
                                                    { contentPointer = possibleOpinion.contentPointer
                                                    , rating = rating
                                                    }
                                                , "Take Back Love"
                                                )
                                in
                                button
                                    [ classList
                                        [ ( "sub-bar-button heart-button", True )
                                        , ( "cursor-progress"
                                          , RT.isMakingRequest shared.apiRequestTracker <|
                                                RT.AddOrRemoveOpinion ContentPointer.Story
                                          )
                                        ]
                                    , onClick <| subMsg newMsg
                                    ]
                                    [ text buttonText ]

                            ( Nothing, _ ) ->
                                button
                                    [ class "sub-bar-button heart-button"
                                    , onClick <|
                                        BaseMessage.SetUserNeedsAuthModal ExplanatoryBlurbs.needAuthSignUpMessage
                                    ]
                                    [ text "Love It" ]

                            _ ->
                                Util.hiddenDiv
                      )
                    ]
                , Util.keyedDiv [ class "sub-bar-ghost hidden" ] []
                , div
                    [ class "view-story-page-content" ]
                    [ div
                        [ class "story-name" ]
                        [ text story.name ]
                    , case ( completedListForLoggedInUser, story.tidbits ) of
                        ( Just hasCompletedList, h :: xs ) ->
                            let
                                totalCompleted =
                                    List.foldl
                                        (\currentBool totalComplete ->
                                            if currentBool then
                                                totalComplete + 1
                                            else
                                                totalComplete
                                        )
                                        0
                                        hasCompletedList

                                totalTidbits =
                                    List.length hasCompletedList

                                doneStory =
                                    totalCompleted == totalTidbits
                            in
                            div
                                []
                                [ div
                                    [ classList [ ( "progress-bar-title", True ) ]
                                    ]
                                    [ if doneStory then
                                        text "story complete"
                                      else
                                        text "you've completed"
                                    ]
                                , div
                                    [ classList [ ( "story-progress-bar-bar", True ) ]
                                    ]
                                    [ ProgressBar.view
                                        { state =
                                            if totalCompleted == 0 then
                                                NotStarted
                                            else if totalCompleted == totalTidbits then
                                                Completed
                                            else
                                                Started totalCompleted
                                        , maxPosition = totalTidbits
                                        , disabledStyling = False
                                        , onClickMsg = BaseMessage.NoOp
                                        , allowClick = False
                                        , textFormat = Percentage
                                        , shiftLeft = False
                                        , alreadyComplete = { complete = doneStory, for = ProgressBar.Story }
                                        }
                                    ]
                                ]

                        _ ->
                            Util.hiddenDiv
                    , case story.tidbits of
                        [] ->
                            div
                                [ class "no-tidbit-text" ]
                                [ text "This story has no tidbits yet!" ]

                        _ ->
                            div
                                [ class "flex-box space-between" ]
                                (List.indexedMap
                                    (\index tidbit ->
                                        Content.fromTidbit tidbit
                                            |> ContentBox.view
                                                { goToMsg = BaseMessage.GoTo { wipeModalError = False }
                                                , darkenBox = Story.tidbitCompletedAtIndex index story
                                                , forStory = Just story.id
                                                }
                                    )
                                    story.tidbits
                                    ++ Util.emptyFlexBoxesForAlignment
                                )
                    ]
                ]
