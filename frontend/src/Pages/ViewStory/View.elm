module Pages.ViewStory.View exposing (..)

import DefaultServices.Util as Util
import Elements.ContentBox exposing (contentBox)
import Elements.ProgressBar exposing (progressBar)
import Html exposing (Html, div, button, text, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Content as Content
import Models.Route as Route
import Models.Story as Story
import Models.Tidbit as Tidbit
import Pages.Model exposing (Shared)
import Pages.ViewStory.Messages exposing (..)


{-| `ViewStory` view.
-}
view : Shared -> Html Msg
view shared =
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
                    [ case nextTidbitInStory of
                        Just _ ->
                            Util.keyedDiv
                                [ class "sub-bar" ]
                                [ ( "view-story-next-tidbit-button"
                                  , case nextTidbitInStory of
                                        Just ( index, routeForViewingTidbit ) ->
                                            button
                                                [ class "sub-bar-button next-tidbit-button"
                                                , onClick <| GoTo routeForViewingTidbit
                                                ]
                                                [ text <| "Continue on Tidbit " ++ (toString <| index + 1)
                                                ]

                                        _ ->
                                            Util.hiddenDiv
                                  )
                                ]

                        _ ->
                            Util.hiddenDiv
                    , case nextTidbitInStory of
                        Just _ ->
                            Util.keyedDiv
                                [ class "sub-bar-ghost hidden" ]
                                []

                        _ ->
                            Util.hiddenDiv
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
                                            [ progressBar (Just totalCompleted) totalTidbits False
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
                                    ((List.indexedMap
                                        (\index tidbit ->
                                            Content.fromTidbit tidbit
                                                |> contentBox
                                                    { goToMsg = GoTo
                                                    , darkenBox = Story.tidbitCompletedAtIndex index story
                                                    , forStory = Just story.id
                                                    }
                                        )
                                        story.tidbits
                                     )
                                        ++ Util.emptyFlexBoxesForAlignment
                                    )
                        ]
                    ]
