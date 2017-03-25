module Pages.ViewStory.View exposing (..)

import DefaultServices.Util as Util
import Elements.ProgressBar exposing (progressBar)
import Html exposing (Html, div, button, text, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Route as Route
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
                                    |> Maybe.map
                                        (Tidbit.getTidbitRoute (Just story.id) >> (,) index)
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
                                                [ text <|
                                                    "Continue on Tidbit "
                                                        ++ (toString <| index + 1)
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
                                div
                                    []
                                    [ div
                                        [ classList [ ( "progress-bar-title", True ) ]
                                        ]
                                        [ text "you've completed" ]
                                    , div
                                        [ classList [ ( "story-progress-bar-bar", True ) ]
                                        ]
                                        [ progressBar
                                            (Just <|
                                                List.foldl
                                                    (\currentBool totalComplete ->
                                                        if currentBool then
                                                            totalComplete + 1
                                                        else
                                                            totalComplete
                                                    )
                                                    0
                                                    hasCompletedList
                                            )
                                            (List.length hasCompletedList)
                                            False
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
                                            div
                                                [ classList
                                                    [ ( "tidbit-box", True )
                                                    , ( "completed"
                                                      , case
                                                            shared.viewingStory
                                                                |> Maybe.andThen .userHasCompleted
                                                        of
                                                            Nothing ->
                                                                False

                                                            Just hasCompletedList ->
                                                                Maybe.withDefault
                                                                    False
                                                                    (Util.getAt
                                                                        hasCompletedList
                                                                        index
                                                                    )
                                                      )
                                                    ]
                                                ]
                                                [ div
                                                    [ class "tidbit-box-name" ]
                                                    [ text <| Tidbit.getName tidbit ]
                                                , div
                                                    [ class "tidbit-box-page-number" ]
                                                    [ text <| toString <| index + 1 ]
                                                , button
                                                    [ class "view-button"
                                                    , onClick <|
                                                        GoTo <|
                                                            Tidbit.getTidbitRoute
                                                                (Just story.id)
                                                                tidbit
                                                    ]
                                                    [ text "VIEW"
                                                    ]
                                                , div
                                                    [ class "completed-icon-div" ]
                                                    [ i
                                                        [ class "material-icons completed-icon" ]
                                                        [ text "check" ]
                                                    ]
                                                ]
                                        )
                                        story.tidbits
                                     )
                                        ++ Util.emptyFlexBoxesForAlignment
                                    )
                        ]
                    ]
