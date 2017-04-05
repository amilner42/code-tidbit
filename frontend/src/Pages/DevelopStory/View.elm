module Pages.DevelopStory.View exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, button, text, i, span)
import Html.Attributes exposing (class, classList, id)
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
                , Util.keyedDiv [ class "sub-bar-ghost hidden" ] []
                , div
                    [ class "create-story-page-content" ]
                    [ div
                        [ class "create-story-page-title"
                        , id "story-tidbits-title"
                        ]
                        [ text story.name ]
                    , div
                        [ classList
                            [ ( "no-tidbit-message", True )
                            , ( "hidden"
                              , not <| (List.length story.tidbits == 0) && (List.length model.tidbitsToAdd == 0)
                              )
                            ]
                        ]
                        [ text "This story has no tidbits yet" ]
                    , div
                        [ class "flex-box space-around" ]
                        (story.tidbits
                            |> List.indexedMap (\index tidbit -> tidbitBox { state = Finalized index } tidbit)
                            |> (flip (++)) (List.map (tidbitBox { state = Added }) model.tidbitsToAdd)
                            |> (flip (++)) Util.emptyFlexBoxesForAlignment
                        )
                    , div
                        [ class "create-story-page-title" ]
                        [ text "Select Tidbits to Add" ]
                    , div
                        [ classList
                            [ ( "no-tidbit-message", True )
                            , ( "hidden"
                              , List.length (userTidbits |> remainingTidbits (story.tidbits ++ model.tidbitsToAdd)) > 0
                              )
                            ]
                        ]
                        [ text "No tidbits remaining" ]
                    , div
                        [ class "flex-box space-around" ]
                        (userTidbits
                            |> remainingTidbits (story.tidbits ++ model.tidbitsToAdd)
                            |> Util.sortByDate Tidbit.getLastModified
                            |> List.reverse
                            |> List.map (tidbitBox { state = NotYetAdded })
                            |> (flip (++)) Util.emptyFlexBoxesForAlignment
                        )
                    ]
                ]

        _ ->
            Util.hiddenDiv


{-| The possible states for a tidbit box, we render differently depending on the state.
-}
type TidbitBoxState
    = NotYetAdded
    | Added
    | Finalized Int


{-| Config for rendering a tidbit box.
-}
type alias TidbitBoxRenderConfig =
    { state : TidbitBoxState
    }


{-| Returns true if the config is set to the `NotYetAdded` state.
-}
isNotYetAdded : TidbitBoxRenderConfig -> Bool
isNotYetAdded config =
    case config.state of
        NotYetAdded ->
            True

        _ ->
            False


{-| Returns true if the config is set to the `Added` state.
-}
isAdded : TidbitBoxRenderConfig -> Bool
isAdded config =
    case config.state of
        Added ->
            True

        _ ->
            False


{-| Returns true if the config is set to the `Finalized` state.
-}
isFinalized : TidbitBoxRenderConfig -> Bool
isFinalized config =
    case config.state of
        Finalized _ ->
            True

        _ ->
            False


{-| The tidbit boxes.
-}
tidbitBox : TidbitBoxRenderConfig -> Tidbit.Tidbit -> Html Msg
tidbitBox renderConfig tidbit =
    div
        [ classList
            [ ( "tidbit-box", True )
            , ( "snipbit", Tidbit.isSnipbit tidbit )
            , ( "bigbit", Tidbit.isBigbit tidbit )
            , ( "not-yet-added", isNotYetAdded renderConfig )
            , ( "added", isAdded renderConfig )
            , ( "finalized", isFinalized renderConfig )
            ]
        , onClick <|
            case renderConfig.state of
                NotYetAdded ->
                    AddTidbit tidbit

                Added ->
                    RemoveTidbit tidbit

                _ ->
                    NoOp
        ]
        [ case renderConfig.state of
            Finalized index ->
                div
                    [ class "tidbit-box-page-number" ]
                    [ text <| toString <| index + 1 ]

            _ ->
                Util.hiddenDiv
        , div
            [ class "tidbit-box-name" ]
            [ text <| Tidbit.getName tidbit ]
        , div
            [ class "view-tidbit"
            , Util.onClickWithoutPropigation <| GoTo <| Tidbit.getTidbitRoute Nothing tidbit
            ]
            [ i [ class "material-icons" ] [ text "remove_red_eye" ]
            , span [] [ text "View" ]
            ]
        ]
