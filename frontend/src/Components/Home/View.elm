module Components.Home.View exposing (..)

import Array
import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model, TidbitType(..))
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3, img, hr)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src)
import Html.Events exposing (onClick, onInput)
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Router


{-| Home Component View.
-}
view : Model -> Shared -> Html Msg
view model shared =
    div
        [ class "home-component-wrapper" ]
        [ div
            [ class "home-component" ]
            [ navbar shared
            , displayViewForRoute model shared
            ]
        ]


{-| Displays the correct view based on the model.
-}
displayViewForRoute : Model -> Shared -> Html Msg
displayViewForRoute model shared =
    case shared.route of
        Route.HomeComponentBrowse ->
            browseView model

        Route.HomeComponentCreate ->
            createView model shared

        Route.HomeComponentCreateSnipbitName ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitDescription ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitLanguage ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitTags ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeIntroduction ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeFrame _ ->
            createSnipbitView model shared

        Route.HomeComponentCreateSnipbitCodeConclusion ->
            createSnipbitView model shared

        Route.HomeComponentProfile ->
            profileView model

        -- This should never happen.
        _ ->
            browseView model


{-| Horizontal navbar to go above the views.
-}
navbar : Shared -> Html Msg
navbar shared =
    let
        browseViewSelected =
            shared.route == Route.HomeComponentBrowse

        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        createViewSelected =
            case shared.route of
                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    True

                _ ->
                    (List.member
                        shared.route
                        [ Route.HomeComponentCreate
                        , Route.HomeComponentCreateSnipbitName
                        , Route.HomeComponentCreateSnipbitDescription
                        , Route.HomeComponentCreateSnipbitLanguage
                        , Route.HomeComponentCreateSnipbitTags
                        , Route.HomeComponentCreateSnipbitCodeIntroduction
                        , Route.HomeComponentCreateSnipbitCodeConclusion
                        ]
                    )
    in
        div [ class "nav" ]
            [ img
                [ class "logo"
                , src "assets/ct-logo.png"
                ]
                []
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", browseViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentBrowse
                ]
                [ text "Browse" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "selected", createViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentCreate
                ]
                [ text "Create" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick <| GoTo Route.HomeComponentProfile
                ]
                [ text "Profile" ]
            ]


{-| The profile view.
-}
profileView : Model -> Html Msg
profileView model =
    div []
        [ button
            [ onClick LogOut ]
            [ text "Log out" ]
        , div
            [ hidden <| Util.isNothing model.logOutError ]
            [ text "Cannot log out right now, try again shortly." ]
        ]


{-| The browse view.
-}
browseView : Model -> Html Msg
browseView model =
    div []
        []


{-| The create view.
-}
createView : Model -> Shared -> Html Msg
createView model shared =
    let
        snipBitDescription : String
        snipBitDescription =
            """SnipBits are uni-language snippets of code that are
            targetted at explaining simple individual concepts or
            answering questions.

            You highlight chunks of the code with attached comments,
            taking your viewers through your code explaining everything
            one step at a time.
            """

        bigBitInfo : String
        bigBitInfo =
            "TODO"

        makeTidbitTypeBox : String -> String -> String -> Msg -> TidbitType -> Html Msg
        makeTidbitTypeBox title subTitle description onClickMsg tidbitType =
            div
                [ class "create-select-tidbit-type" ]
                (if model.showInfoFor == (Just tidbitType) then
                    [ div
                        [ class "description-title" ]
                        [ text <| toString tidbitType ++ " Info" ]
                    , div
                        [ class "description-text" ]
                        [ text description ]
                    , button
                        [ class "back-button"
                        , onClick <| ShowInfoFor Nothing
                        ]
                        [ text "back" ]
                    ]
                 else
                    [ div
                        [ class "create-select-tidbit-type-title" ]
                        [ text title ]
                    , div
                        [ class "create-select-tidbit-type-sub-title" ]
                        [ text subTitle ]
                    , button
                        [ class "info-button"
                        , onClick <| ShowInfoFor <| Just tidbitType
                        ]
                        [ text "more info" ]
                    , button
                        [ class "select-button"
                        , onClick onClickMsg
                        ]
                        [ text "select" ]
                    ]
                )
    in
        div
            []
            [ div
                []
                [ h1
                    [ class "create-select-tidbit-title" ]
                    [ text "Select Tidbit Type" ]
                , div
                    [ class "create-select-tidbit-box" ]
                    [ makeTidbitTypeBox
                        "SnipBit"
                        "Excellent for answering questions"
                        snipBitDescription
                        (GoTo Route.HomeComponentCreateSnipbitName)
                        SnipBit
                    , makeTidbitTypeBox
                        "BigBit"
                        "Designed for larger tutorials"
                        bigBitInfo
                        (NoOp)
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
                ]
            ]


{-| View for creating a snipbit.
-}
createSnipbitView : Model -> Shared -> Html Msg
createSnipbitView model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList
                    [ ( "hidden"
                      , String.isEmpty model.creatingSnipbitData.languageQuery
                            || Util.isNotNothing
                                model.creatingSnipbitData.language
                      )
                    ]
                ]
                [ Html.map
                    SnipbitUpdateACState
                    (AC.view
                        acViewConfig
                        model.creatingSnipbitData.languageListHowManyToShow
                        model.creatingSnipbitData.languageQueryACState
                        (filterLanguagesByQuery
                            model.creatingSnipbitData.languageQuery
                            shared.languages
                        )
                    )
                ]

        acViewConfig : AC.ViewConfig ( Editor.Language, String )
        acViewConfig =
            let
                customizedLi keySelected mouseSelected languagePair =
                    { attributes =
                        [ classList
                            [ ( "lang-select-ac-item", True )
                            , ( "key-selected", keySelected || mouseSelected )
                            ]
                        ]
                    , children = [ Html.text (Tuple.second languagePair) ]
                    }
            in
                AC.viewConfig
                    { toId = (toString << Tuple.first)
                    , ul = [ class "lang-select-ac" ]
                    , li = customizedLi
                    }

        createSnipbitNavbar : Html Msg
        createSnipbitNavbar =
            div
                [ classList [ ( "create-snipbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-snipbit-tab", True )
                        , ( "create-snipbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitName
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitName
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-snipbit-tab", True )
                        , ( "create-snipbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitDescription
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-snipbit-tab", True )
                        , ( "create-snipbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitLanguage
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitLanguage
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-snipbit-tab", True )
                        , ( "create-snipbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitTags
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitTags
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-snipbit-tab", True )
                        , ( "create-snipbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateSnipbitCodeIntroduction ->
                                    True

                                Route.HomeComponentCreateSnipbitCodeConclusion ->
                                    True

                                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                                    True

                                _ ->
                                    False
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                    ]
                    [ text "Code" ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-snipbit-name" ]
                [ input
                    [ placeholder "Name"
                    , onInput SnipbitUpdateName
                    , value model.creatingSnipbitData.name
                    , Util.onEnter <|
                        if String.isEmpty model.creatingSnipbitData.name then
                            NoOp
                        else
                            GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    []
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                [ class "create-snipbit-description" ]
                [ textarea
                    [ class "create-snipbit-description-box"
                    , placeholder "Description"
                    , onInput SnipbitUpdateDescription
                    , value model.creatingSnipbitData.description
                    ]
                    []
                ]

        languageView : Html Msg
        languageView =
            div
                [ class "create-snipbit-language" ]
                [ input
                    [ placeholder "Language"
                    , id "language-query-input"
                    , onInput SnipbitUpdateLanguageQuery
                    , value model.creatingSnipbitData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.creatingSnipbitData.language
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| SnipbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.creatingSnipbitData.language
                          )
                        ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            let
                currentTags =
                    div
                        [ class "current-tags" ]
                        (List.map
                            (\tagName ->
                                div
                                    [ class "tag" ]
                                    [ text tagName
                                    , button
                                        [ onClick <| SnipbitRemoveTag tagName ]
                                        [ text "X" ]
                                    ]
                            )
                            model.creatingSnipbitData.tags
                        )
            in
                div
                    [ class "create-snipbit-tags" ]
                    [ input
                        [ placeholder "Tags"
                        , onInput SnipbitUpdateTagInput
                        , value model.creatingSnipbitData.tagInput
                        , Util.onEnter <|
                            SnipbitAddTag
                                model.creatingSnipbitData.tagInput
                        ]
                        []
                    , currentTags
                    ]

        tidbitView : Html Msg
        tidbitView =
            let
                body =
                    case shared.route of
                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Introduction"
                                    , onInput <| SnipbitUpdateIntroduction
                                    , value model.creatingSnipbitData.introduction
                                    ]
                                    []
                                ]

                        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                div
                                    [ class "comment-body" ]
                                    [ textarea
                                        [ placeholder <|
                                            "Frame "
                                                ++ (toString <| frameNumber)
                                        , onInput <|
                                            SnipbitUpdateFrameComment frameIndex
                                        , value <|
                                            case
                                                (Array.get
                                                    frameIndex
                                                    model.creatingSnipbitData.highlightedComments
                                                )
                                            of
                                                Nothing ->
                                                    ""

                                                Just maybeHC ->
                                                    case maybeHC.comment of
                                                        Nothing ->
                                                            ""

                                                        Just comment ->
                                                            comment
                                        ]
                                        []
                                    ]

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Conclusion"
                                    , onInput <| SnipbitUpdateConclusion
                                    , value model.creatingSnipbitData.conclusion
                                    ]
                                    []
                                ]

                        -- Should never happen.
                        _ ->
                            div
                                []
                                []

                tabBar =
                    let
                        dynamicFrameButtons =
                            (Array.toList <|
                                Array.indexedMap
                                    (\index maybeHighlightedComment ->
                                        button
                                            [ onClick <|
                                                GoTo <|
                                                    Route.HomeComponentCreateSnipbitCodeFrame
                                                        (index + 1)
                                            , classList
                                                [ ( "selected-frame"
                                                  , shared.route
                                                        == (Route.HomeComponentCreateSnipbitCodeFrame <|
                                                                index
                                                                    + 1
                                                           )
                                                  )
                                                ]
                                            ]
                                            [ text <| toString <| index + 1 ]
                                    )
                                    model.creatingSnipbitData.highlightedComments
                            )
                    in
                        div
                            []
                            (List.concat
                                [ [ button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateSnipbitCodeIntroduction
                                              )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                  , button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateSnipbitCodeConclusion
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateSnipbitCodeConclusion
                                              )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                  , button
                                        [ class "action-button plus-button"
                                        , onClick <| SnipbitAddFrame
                                        ]
                                        [ text "+" ]
                                  , button
                                        [ class "action-button"
                                        , onClick <| SnipbitRemoveFrame
                                        , disabled <|
                                            Array.length
                                                model.creatingSnipbitData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                  , hr [] []
                                  ]
                                , dynamicFrameButtons
                                ]
                            )
            in
                div
                    [ class "create-snipbit-code" ]
                    [ Editor.editor "create-snipbit-code-editor"
                    , div
                        [ class "comment-creator" ]
                        [ body
                        , tabBar
                        ]
                    ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.HomeComponentCreateSnipbitName ->
                    nameView

                Route.HomeComponentCreateSnipbitDescription ->
                    descriptionView

                Route.HomeComponentCreateSnipbitLanguage ->
                    languageView

                Route.HomeComponentCreateSnipbitTags ->
                    tagsView

                Route.HomeComponentCreateSnipbitCodeIntroduction ->
                    tidbitView

                Route.HomeComponentCreateSnipbitCodeConclusion ->
                    tidbitView

                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView

        -- Disabled publish button.
        disabledPublishButton =
            button
                [ class "create-snipbit-disabled-publish-button"
                , disabled True
                ]
                [ text "Publish" ]

        {- It should be `disabledPublishButton` unless
           everything is filled out in which case it should be
           the publish button with the info filled for an
           event handler to call the API.
        -}
        currentPublishButton =
            let
                tidbitData =
                    model.creatingSnipbitData
            in
                case tidbitData.language of
                    Nothing ->
                        disabledPublishButton

                    Just theLanguage ->
                        if
                            (tidbitData.name /= "")
                                && (tidbitData.description /= "")
                                && (List.length tidbitData.tags > 0)
                                && (tidbitData.code /= "")
                                && (tidbitData.introduction /= "")
                                && (tidbitData.conclusion /= "")
                        then
                            let
                                filledHighlightedComments =
                                    Array.foldr
                                        (\maybeHC previousHC ->
                                            case ( maybeHC.range, maybeHC.comment ) of
                                                ( Just aRange, Just aComment ) ->
                                                    if
                                                        (String.length aComment > 0)
                                                            && (not <| Range.isEmptyRange aRange)
                                                    then
                                                        { range = aRange
                                                        , comment = aComment
                                                        }
                                                            :: previousHC
                                                    else
                                                        previousHC

                                                _ ->
                                                    previousHC
                                        )
                                        []
                                        tidbitData.highlightedComments
                            in
                                if
                                    (List.length filledHighlightedComments)
                                        == (Array.length tidbitData.highlightedComments)
                                then
                                    button
                                        [ classList
                                            [ ( "create-snipbit-publish-button", True )
                                            ]
                                        , onClick <|
                                            SnipbitPublish
                                                { language = theLanguage
                                                , name = tidbitData.name
                                                , description = tidbitData.description
                                                , tags = tidbitData.tags
                                                , code = tidbitData.code
                                                , introduction = tidbitData.introduction
                                                , conclusion = tidbitData.conclusion
                                                , highlightedComments = Array.fromList filledHighlightedComments
                                                }
                                        ]
                                        [ text "Publish" ]
                                else
                                    disabledPublishButton
                        else
                            disabledPublishButton
    in
        div
            [ class "create-snipbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "create-snipbit-back-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "create-snipbit-reset-button"
                    , onClick <| SnipbitReset
                    ]
                    [ text "Reset" ]
                , currentPublishButton
                ]
            , div
                []
                [ createSnipbitNavbar
                , viewForTab
                ]
            ]
