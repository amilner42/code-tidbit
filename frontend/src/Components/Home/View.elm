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
import Models.BasicTidbit as BasicTidbit
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

        Route.HomeComponentCreateBasicName ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicDescription ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicLanguage ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTags ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTidbitIntroduction ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTidbitFrame _ ->
            createBasicTidbitView model shared

        Route.HomeComponentCreateBasicTidbitConclusion ->
            createBasicTidbitView model shared

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
                Route.HomeComponentCreateBasicTidbitFrame _ ->
                    True

                _ ->
                    (List.member
                        shared.route
                        [ Route.HomeComponentCreate
                        , Route.HomeComponentCreateBasicName
                        , Route.HomeComponentCreateBasicDescription
                        , Route.HomeComponentCreateBasicLanguage
                        , Route.HomeComponentCreateBasicTags
                        , Route.HomeComponentCreateBasicTidbitIntroduction
                        , Route.HomeComponentCreateBasicTidbitConclusion
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
                        (GoTo Route.HomeComponentCreateBasicName)
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


{-| View for creating a basic tidbit.
-}
createBasicTidbitView : Model -> Shared -> Html Msg
createBasicTidbitView model shared =
    let
        currentRoute : Route.Route
        currentRoute =
            shared.route

        viewMenu : Html Msg
        viewMenu =
            div
                [ classList
                    [ ( "hidden"
                      , String.isEmpty model.creatingBasicTidbitData.languageQuery
                            || Util.isNotNothing
                                model.creatingBasicTidbitData.language
                      )
                    ]
                ]
                [ Html.map
                    BasicTidbitUpdateACState
                    (AC.view
                        acViewConfig
                        model.creatingBasicTidbitData.languageListHowManyToShow
                        model.creatingBasicTidbitData.languageQueryACState
                        (filterLanguagesByQuery
                            model.creatingBasicTidbitData.languageQuery
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

        createBasicTidbitNavbar : Html Msg
        createBasicTidbitNavbar =
            div
                [ classList [ ( "create-basic-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicName
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicName
                    ]
                    [ text "Name" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicDescription
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicDescription
                    ]
                    [ text "Description" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicLanguage
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicLanguage
                    ]
                    [ text "Language" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBasicTags
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicTags
                    ]
                    [ text "Tags" ]
                , div
                    [ classList
                        [ ( "create-basic-tidbit-tab", True )
                        , ( "create-basic-tidbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateBasicTidbitIntroduction ->
                                    True

                                Route.HomeComponentCreateBasicTidbitConclusion ->
                                    True

                                Route.HomeComponentCreateBasicTidbitFrame _ ->
                                    True

                                _ ->
                                    False
                          )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBasicTidbitIntroduction
                    ]
                    [ text "Tidbit" ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-basic-tidbit-name" ]
                [ input
                    [ placeholder "Name"
                    , onInput BasicTidbitUpdateName
                    , value model.creatingBasicTidbitData.name
                    , Util.onEnter <|
                        if String.isEmpty model.creatingBasicTidbitData.name then
                            NoOp
                        else
                            GoTo Route.HomeComponentCreateBasicDescription
                    ]
                    []
                ]

        descriptionView : Html Msg
        descriptionView =
            div
                [ class "create-basic-tidbit-description" ]
                [ textarea
                    [ class "create-basic-tidbit-description-box"
                    , placeholder "Description"
                    , onInput BasicTidbitUpdateDescription
                    , value model.creatingBasicTidbitData.description
                    ]
                    []
                ]

        languageView : Html Msg
        languageView =
            div
                [ class "create-basic-tidbit-language" ]
                [ input
                    [ placeholder "Language"
                    , id "language-query-input"
                    , onInput BasicTidbitUpdateLanguageQuery
                    , value model.creatingBasicTidbitData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.creatingBasicTidbitData.language
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| BasicTidbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.creatingBasicTidbitData.language
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
                                        [ onClick <| BasicTidbitRemoveTag tagName ]
                                        [ text "X" ]
                                    ]
                            )
                            model.creatingBasicTidbitData.tags
                        )
            in
                div
                    [ class "create-basic-tidbit-tags" ]
                    [ input
                        [ placeholder "Tags"
                        , onInput BasicTidbitUpdateTagInput
                        , value model.creatingBasicTidbitData.tagInput
                        , Util.onEnter <|
                            BasicTidbitAddTag
                                model.creatingBasicTidbitData.tagInput
                        ]
                        []
                    , currentTags
                    ]

        tidbitView : Html Msg
        tidbitView =
            let
                body =
                    case shared.route of
                        Route.HomeComponentCreateBasicTidbitIntroduction ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Introduction"
                                    , onInput <| BasicTidbitUpdateIntroduction
                                    , value model.creatingBasicTidbitData.introduction
                                    ]
                                    []
                                ]

                        Route.HomeComponentCreateBasicTidbitFrame frameNumber ->
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
                                            BasicTidbitUpdateFrameComment frameIndex
                                        , value <|
                                            case
                                                (Array.get
                                                    frameIndex
                                                    model.creatingBasicTidbitData.highlightedComments
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

                        Route.HomeComponentCreateBasicTidbitConclusion ->
                            div
                                [ class "comment-body" ]
                                [ textarea
                                    [ placeholder "Conclusion"
                                    , onInput <| BasicTidbitUpdateConclusion
                                    , value model.creatingBasicTidbitData.conclusion
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
                                                    Route.HomeComponentCreateBasicTidbitFrame
                                                        (index + 1)
                                            , classList
                                                [ ( "selected-frame"
                                                  , shared.route
                                                        == (Route.HomeComponentCreateBasicTidbitFrame <|
                                                                index
                                                                    + 1
                                                           )
                                                  )
                                                ]
                                            ]
                                            [ text <| toString <| index + 1 ]
                                    )
                                    model.creatingBasicTidbitData.highlightedComments
                            )
                    in
                        div
                            []
                            (List.concat
                                [ [ button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateBasicTidbitIntroduction
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateBasicTidbitIntroduction
                                              )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                  , button
                                        [ onClick <|
                                            GoTo Route.HomeComponentCreateBasicTidbitConclusion
                                        , classList
                                            [ ( "selected-frame"
                                              , shared.route
                                                    == Route.HomeComponentCreateBasicTidbitConclusion
                                              )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                  , button
                                        [ class "action-button plus-button"
                                        , onClick <| BasicTidbitAddFrame
                                        ]
                                        [ text "+" ]
                                  , button
                                        [ class "action-button"
                                        , onClick <| BasicTidbitRemoveFrame
                                        , disabled <|
                                            Array.length
                                                model.creatingBasicTidbitData.highlightedComments
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
                    [ class "create-basic-tidbit-code" ]
                    [ Editor.editor "basic-tidbit-code-editor"
                    , div
                        [ class "comment-creator" ]
                        [ body
                        , tabBar
                        ]
                    ]

        viewForTab : Html Msg
        viewForTab =
            case currentRoute of
                Route.HomeComponentCreateBasicName ->
                    nameView

                Route.HomeComponentCreateBasicDescription ->
                    descriptionView

                Route.HomeComponentCreateBasicLanguage ->
                    languageView

                Route.HomeComponentCreateBasicTags ->
                    tagsView

                Route.HomeComponentCreateBasicTidbitIntroduction ->
                    tidbitView

                Route.HomeComponentCreateBasicTidbitConclusion ->
                    tidbitView

                Route.HomeComponentCreateBasicTidbitFrame _ ->
                    tidbitView

                -- Default to name view.
                _ ->
                    nameView

        -- Disabled publish button.
        disabledPublishButton =
            button
                [ class "create-basic-tidbit-disabled-publish-button"
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
                    model.creatingBasicTidbitData
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
                                            [ ( "create-basic-tidbit-publish-button", True )
                                            ]
                                        , onClick <|
                                            BasicTidbitPublish
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
            [ class "create-basic-tidbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "create-basic-tidbit-back-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "create-basic-tidbit-reset-button"
                    , onClick <| ResetCreateBasicTidbit
                    ]
                    [ text "Reset" ]
                , currentPublishButton
                ]
            , div
                []
                [ createBasicTidbitNavbar
                , viewForTab
                ]
            ]
