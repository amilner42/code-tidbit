module Pages.Create.View exposing (..)

import DefaultServices.Util as Util
import Html exposing (Html, div, text, button, i)
import Html.Attributes exposing (class, classList)
import Html.Events exposing (onClick)
import Models.Route as Route
import Models.TidbitType exposing (TidbitType(..))
import Pages.Create.Messages exposing (..)
import Pages.Create.Model exposing (..)
import Pages.Model exposing (Shared)


{-| `Create` view.
-}
view : Model -> Shared -> Html Msg
view model shared =
    let
        snipBitDescription : String
        snipBitDescription =
            """SnipBits are uni-language snippets of code that are targetted at explaining simple individual concepts or
            answering questions.

            You highlight chunks of the code with attached comments, taking your viewers through your code explaining
            everything one step at a time.
            """

        bigBitInfo : String
        bigBitInfo =
            """BigBits are multi-language projects of code targetted at simplifying larger tutorials which require their
            own file structure.

            You highlight chunks of code and attach comments automatically taking your user through all the files and
            folders in a directed fashion while still letting them explore themselves.
            """

        makeTidbitTypeBox : String -> String -> String -> Msg -> TidbitType -> Html Msg
        makeTidbitTypeBox title subTitle description onClickMsg tidbitType =
            div
                [ class "create-select-tidbit-type" ]
                (if model.showInfoFor == (Just tidbitType) then
                    [ div
                        [ class "description-text" ]
                        [ text description ]
                    , button
                        [ class "back-button"
                        , onClick <| ShowInfoFor Nothing
                        ]
                        [ text "Back" ]
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
                        , onClick <| ShowInfoFor <| Just tidbitType
                        ]
                        [ text "help_outline" ]
                    , button
                        [ class "select-button"
                        , onClick onClickMsg
                        ]
                        [ text "CREATE" ]
                    ]
                )

        yourStoriesHtml : Html Msg
        yourStoriesHtml =
            case shared.userStories of
                -- Should never happen.
                Nothing ->
                    Util.hiddenDiv

                Just userStories ->
                    div
                        [ class "develop-stories" ]
                        [ div
                            [ classList [ ( "flex-box space-around", True ) ]
                            ]
                            ([ div
                                [ class "create-story-box"
                                , onClick <| GoTo <| Route.CreateStoryNamePage Nothing
                                ]
                                [ i
                                    [ class "material-icons add-story-box-icon" ]
                                    [ text "add" ]
                                ]
                             ]
                                ++ (List.map
                                        (\story ->
                                            div
                                                [ class "story-box"
                                                , onClick <| GoTo <| Route.DevelopStoryPage story.id
                                                ]
                                                [ div
                                                    [ class "story-box-name" ]
                                                    [ text story.name ]
                                                ]
                                        )
                                        (List.reverse <| Util.sortByDate .lastModified userStories)
                                   )
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
                    snipBitDescription
                    (GoTo Route.CreateSnipbitNamePage)
                    SnipBit
                , makeTidbitTypeBox
                    "BigBit"
                    "Explain a full project"
                    bigBitInfo
                    (GoTo Route.CreateBigbitNamePage)
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
