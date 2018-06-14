module Pages.DevelopStory.View exposing (..)

import DefaultServices.Util as Util
import Elements.Simple.Editor exposing (prettyPrintLanguages)
import Html exposing (Html, button, div, i, span, text)
import Html.Attributes exposing (class, classList, id)
import Html.Events exposing (onClick)
import Models.RequestTracker as RT
import Models.Route as Route
import Models.Tidbit as Tidbit
import Pages.DevelopStory.Messages exposing (..)
import Pages.DevelopStory.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)


{-| `DevelopStory` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    case ( model.story, shared.userTidbits ) of
        ( Just story, Just userTidbits ) ->
            div
                [ class "create-story-page" ]
                [ Util.keyedDiv
                    [ class "sub-bar" ]
                    [ ( "create-story-page-sub-bar-view-story-button"
                      , Route.navigationNode
                            (Just
                                ( Route.Route <| Route.ViewStoryPage story.id
                                , BaseMessage.GoTo { wipeModalError = False } <| Route.ViewStoryPage story.id
                                )
                            )
                            []
                            [ button [ class "sub-bar-button " ] [ text "View Story" ] ]
                      )
                    , ( "create-story-page-sub-bar-edit-info-button"
                      , Route.navigationNode
                            (Just
                                ( Route.Route <| Route.CreateStoryNamePage <| Just story.id
                                , BaseMessage.GoTo { wipeModalError = False } <|
                                    Route.CreateStoryNamePage <|
                                        Just story.id
                                )
                            )
                            []
                            [ button
                                [ class "sub-bar-button edit-information" ]
                                [ text "Edit Information" ]
                            ]
                      )
                    , ( "create-story-page-sub-bar-add-tidbits-button"
                      , case model.tidbitsToAdd of
                            [] ->
                                button
                                    [ class "disabled-publish-button" ]
                                    [ text "Add Tidbits" ]

                            tidbits ->
                                button
                                    [ classList
                                        [ ( "publish-button", True )
                                        , ( "cursor-progress"
                                          , RT.isMakingRequest shared.apiRequestTracker RT.PublishNewTidbitsToStory
                                          )
                                        ]
                                    , onClick <| subMsg <| PublishAddedTidbits story.id tidbits
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
                            |> List.indexedMap
                                (\index tidbit -> tidbitBox { state = Finalized index, subMsg = subMsg } tidbit)
                            |> flip (++) (List.map (tidbitBox { state = Added, subMsg = subMsg }) model.tidbitsToAdd)
                            |> flip (++) Util.emptyFlexBoxesForAlignment
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
                            |> List.map (tidbitBox { state = NotYetAdded, subMsg = subMsg })
                            |> flip (++) Util.emptyFlexBoxesForAlignment
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
type alias TidbitBoxRenderConfig subMsg baseMsg =
    { state : TidbitBoxState
    , subMsg : subMsg -> baseMsg
    }


{-| Returns true if the config is set to the `NotYetAdded` state.
-}
isNotYetAdded : TidbitBoxRenderConfig subMsg baseMsg -> Bool
isNotYetAdded config =
    case config.state of
        NotYetAdded ->
            True

        _ ->
            False


{-| Returns true if the config is set to the `Added` state.
-}
isAdded : TidbitBoxRenderConfig subMsg baseMsg -> Bool
isAdded config =
    case config.state of
        Added ->
            True

        _ ->
            False


{-| Returns true if the config is set to the `Finalized` state.
-}
isFinalized : TidbitBoxRenderConfig subMsg baseMsg -> Bool
isFinalized config =
    case config.state of
        Finalized _ ->
            True

        _ ->
            False


{-| The tidbit boxes.
-}
tidbitBox : TidbitBoxRenderConfig Msg BaseMessage.Msg -> Tidbit.Tidbit -> Html BaseMessage.Msg
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
                    renderConfig.subMsg <| AddTidbit tidbit

                Added ->
                    renderConfig.subMsg <| RemoveTidbit tidbit

                _ ->
                    BaseMessage.NoOp
        ]
        [ case renderConfig.state of
            Finalized index ->
                div
                    [ class "tidbit-box-page-number" ]
                    [ text <| (++) "#" <| toString <| index + 1 ]

            _ ->
                Util.hiddenDiv
        , div
            [ class "tidbit-box-name" ]
            [ text <| Tidbit.getName tidbit ]
        , i
            [ class "view-tidbit material-icons"
            , Util.onClickWithoutPropigation <|
                BaseMessage.GoTo { wipeModalError = False } <|
                    Tidbit.getTidbitRoute Nothing tidbit
            ]
            [ text "open_in_new" ]
        , div
            [ class "tidbit-box-languages" ]
            [ text <| prettyPrintLanguages <| Tidbit.getLanguages tidbit
            ]
        , div
            [ class "tidbit-box-opinions" ]
            [ div [ class "like-count" ] [ text <| toString <| Tidbit.getLikes tidbit ]
            , i [ class "material-icons" ] [ text "favorite" ]
            ]
        ]
