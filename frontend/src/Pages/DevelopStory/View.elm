module Pages.DevelopStory.View exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, button, text)
import Html.Attributes exposing (class, id)
import Html.Events exposing (onClick)
import Models.Route as Route
import Models.Tidbit as Tidbit
import Pages.DevelopStory.Messages exposing (..)
import Pages.DevelopStory.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `DevelopStory` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    case ( model.story, shared.userTidbits ) of
        ( Just story, Just userTidbits ) ->
            div
                [ class "create-story-page" ]
                [ Util.keyedDiv
                    [ class "sub-bar" ]
                    [ ( "create-story-page-sub-bar-view-story-button"
                      , button
                            [ class "sub-bar-button "
                            , onClick <| GoTo <| Route.ViewStoryPage story.id
                            ]
                            [ text "View Story" ]
                      )
                    , ( "create-story-page-sub-bar-edit-info-button"
                      , button
                            [ class "sub-bar-button edit-information"
                            , onClick <| GoTo <| Route.CreateStoryNamePage <| Just story.id
                            ]
                            [ text "Edit Information" ]
                      )
                    , ( "create-story-page-sub-bar-add-tidbits-button"
                      , case model.tidbitsToAdd of
                            [] ->
                                button
                                    [ class "disabled-publish-button" ]
                                    [ text "Add Tidbits" ]

                            tidbits ->
                                button
                                    [ class "publish-button"
                                    , onClick <| PublishAddedTidbits story.id tidbits
                                    ]
                                    [ text "Add Tidbits" ]
                      )
                    ]
                , Util.keyedDiv
                    [ class "sub-bar-ghost hidden" ]
                    []
                , div
                    [ class "create-story-page-content" ]
                    [ div
                        [ class "page-content-bar" ]
                        [ div
                            [ class "page-content-bar-title"
                            , id "story-tidbits-title"
                            ]
                            [ text "Story Tidbits" ]
                        , div
                            [ class "page-content-bar-line" ]
                            []
                        , div
                            [ class "flex-box space-between" ]
                            ((List.indexedMap
                                (\index tidbit ->
                                    div
                                        [ class "tidbit-box" ]
                                        [ div
                                            [ class "tidbit-box-name" ]
                                            [ text <| Tidbit.getName tidbit ]
                                        , div
                                            [ class "tidbit-box-type-name" ]
                                            [ text <| Tidbit.getTypeName tidbit ]
                                        , div
                                            [ class "tidbit-box-page-number" ]
                                            [ text <| toString <| index + 1 ]
                                        , button
                                            [ class "full-view-button"
                                            , onClick <| GoTo <| Tidbit.getTidbitRoute Nothing tidbit
                                            ]
                                            [ text "VIEW" ]
                                        ]
                                )
                                story.tidbits
                             )
                                ++ (List.map
                                        (\tidbit ->
                                            div
                                                [ class "tidbit-box not-yet-added" ]
                                                [ div
                                                    [ class "tidbit-box-name" ]
                                                    [ text <| Tidbit.getName tidbit ]
                                                , div
                                                    [ class "tidbit-box-type-name" ]
                                                    [ text <| Tidbit.getTypeName tidbit ]
                                                , button
                                                    [ class "remove-button"
                                                    , onClick <| RemoveTidbit tidbit
                                                    ]
                                                    [ text "REMOVE" ]
                                                ]
                                        )
                                        model.tidbitsToAdd
                                   )
                                ++ Util.emptyFlexBoxesForAlignment
                            )
                        ]
                    , div
                        [ class "page-content-bar" ]
                        [ div
                            [ class "page-content-bar-title" ]
                            [ text "Your Tidbits" ]
                        , div
                            [ class "page-content-bar-line" ]
                            []
                        , div
                            [ class "flex-box space-between" ]
                            ((List.map
                                (\tidbit ->
                                    div
                                        [ class "tidbit-box" ]
                                        [ div
                                            [ class "tidbit-box-name" ]
                                            [ text <| Tidbit.getName tidbit ]
                                        , div
                                            [ class "tidbit-box-type-name" ]
                                            [ text <| Tidbit.getTypeName tidbit ]
                                        , button
                                            [ class "view-tidbit"
                                            , onClick <| GoTo <| Tidbit.getTidbitRoute Nothing tidbit
                                            ]
                                            [ text "VIEW" ]
                                        , button
                                            [ class "add-tidbit"
                                            , onClick <| AddTidbit tidbit
                                            ]
                                            [ text "ADD" ]
                                        ]
                                )
                                (userTidbits
                                    |> remainingTidbits (story.tidbits ++ model.tidbitsToAdd)
                                    |> Util.sortByDate Tidbit.getLastModified
                                    |> List.reverse
                                )
                             )
                                ++ Util.emptyFlexBoxesForAlignment
                            )
                        ]
                    ]
                ]

        _ ->
            Util.hiddenDiv
