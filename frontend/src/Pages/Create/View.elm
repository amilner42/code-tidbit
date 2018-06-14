module Pages.Create.View exposing (..)

import DefaultServices.Util as Util
import Elements.Simple.Editor exposing (prettyPrintLanguages)
import ExplanatoryBlurbs exposing (bigbitInfo, snipbitInfo)
import Html exposing (Html, button, div, i, text)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Route as Route
import Models.TidbitType exposing (TidbitType(..))
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)


{-| `Create` view.
-}
view : (Msg -> BaseMessage.Msg) -> Model -> Shared -> Html BaseMessage.Msg
view subMsg model shared =
    let
        makeTidbitTypeBox : String -> String -> String -> ( Route.Route, BaseMessage.Msg ) -> TidbitType -> Html BaseMessage.Msg
        makeTidbitTypeBox title subTitle description ( route, onClickMsg ) tidbitType =
            div
                [ class "create-select-tidbit-type" ]
                (if model.showInfoFor == Just tidbitType then
                    [ div
                        [ class "description-text" ]
                        [ text description ]
                    , button
                        [ class "back-button"
                        , onClick <| subMsg <| ShowInfoFor Nothing
                        ]
                        [ text "BACK" ]
                    ]
                 else
                    [ div
                        [ class "create-select-tidbit-type-title" ]
                        [ text title ]
                    , div
                        [ class "create-select-tidbit-type-sub-title" ]
                        [ text subTitle ]
                    , i
                        [ class "material-icons info-icon"
                        , onClick <| subMsg <| ShowInfoFor <| Just tidbitType
                        ]
                        [ text "help_outline" ]
                    , Route.navigationNode
                        (Just ( Route.Route route, onClickMsg ))
                        [ class "select-button" ]
                        [ text "CREATE" ]
                    ]
                )

        yourStoriesHtml : Html BaseMessage.Msg
        yourStoriesHtml =
            case shared.userStories of
                Nothing ->
                    Util.hiddenDiv

                Just userStories ->
                    div
                        [ class "develop-stories" ]
                        [ div
                            [ classList [ ( "flex-box space-around", True ) ]
                            ]
                            ([ Route.navigationNode
                                (Just
                                    ( Route.Route <| Route.CreateStoryNamePage Nothing
                                    , BaseMessage.GoTo { wipeModalError = False } <| Route.CreateStoryNamePage Nothing
                                    )
                                )
                                [ class "create-story-box" ]
                                [ i
                                    [ class "material-icons add-story-box-icon" ]
                                    [ text "add" ]
                                ]
                             ]
                                ++ List.map
                                    (\story ->
                                        Route.navigationNode
                                            (Just
                                                ( Route.Route <| Route.DevelopStoryPage story.id
                                                , BaseMessage.GoTo { wipeModalError = False } <|
                                                    Route.DevelopStoryPage story.id
                                                )
                                            )
                                            [ class "story-box" ]
                                            [ div
                                                [ class "story-box-name" ]
                                                [ text story.name ]
                                            , div
                                                [ class "story-box-languages" ]
                                                [ text <| prettyPrintLanguages <| story.languages
                                                ]
                                            , div
                                                [ class "story-box-tidbit-count" ]
                                                [ text <| Util.xThings "tidbit" "s" <| List.length story.tidbitPointers ]
                                            , div
                                                [ class "story-box-opinions" ]
                                                [ i [ class "material-icons" ] [ text "favorite" ]
                                                , div [ class "like-count" ] [ text <| toString <| story.likes ]
                                                ]
                                            ]
                                    )
                                    (List.reverse <| Util.sortByDate .lastModified userStories)
                                ++ Util.emptyFlexBoxesForAlignment
                            )
                        ]
    in
    div
        [ class "create-page" ]
        [ div
            [ class "title-banner" ]
            [ text "CREATE TIDBIT" ]
        , div
            [ class "make-tidbits" ]
            [ makeTidbitTypeBox
                "SnipBit"
                "Explain a chunk of code"
                snipbitInfo
                ( Route.CreateSnipbitInfoPage, BaseMessage.GoTo { wipeModalError = False } Route.CreateSnipbitInfoPage )
                SnipBit
            , makeTidbitTypeBox
                "BigBit"
                "Explain a full project"
                bigbitInfo
                ( Route.CreateBigbitNamePage, BaseMessage.GoTo { wipeModalError = False } Route.CreateBigbitNamePage )
                BigBit
            , div
                [ class "create-select-tidbit-type-coming-soon" ]
                [ div
                    [ class "coming-soon-text" ]
                    [ text "More Coming Soon" ]
                , div
                    [ class "coming-soon-sub-text" ]
                    [ text "We are working on it" ]
                ]
            ]
        , div
            [ class "title-banner story-banner" ]
            [ text "DEVELOP STORY" ]
        , yourStoriesHtml
        ]
