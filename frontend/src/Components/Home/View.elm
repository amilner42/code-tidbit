module Components.Home.View exposing (..)

import Array
import Autocomplete as AC
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model as Model exposing (Model, TidbitType(..), isViewBigbitRHCTabOpen, isViewBigbitFSTabOpen, isViewBigbitTutorialTabOpen, isViewBigbitFSOpen)
import Components.Home.Update exposing (filterLanguagesByQuery)
import Components.Model exposing (Shared, kkUpdateWrapper)
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Dict
import Elements.Editor as Editor
import Html exposing (Html, div, text, textarea, button, input, h1, h3, img, hr, i)
import Html.Attributes exposing (class, classList, disabled, placeholder, value, hidden, id, src, style)
import Html.Events exposing (onClick, onInput)
import Models.Bigbit as Bigbit
import Elements.FileStructure as FS
import Elements.Markdown exposing (githubMarkdown)
import Keyboard.Extra as KK
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit


{-| A google-material-design check-icon.
-}
checkIcon : Html msg
checkIcon =
    i
        [ class "material-icons check-icon" ]
        [ text "check" ]


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


{-| Helper function for creating the HTML tags in the tag-tab. Currently used
in both snipbits and bigbits.
-}
makeHTMLTags : (String -> Msg) -> List String -> Html Msg
makeHTMLTags closeTagMsg tags =
    div
        [ class "current-tags" ]
        (List.map
            (\tagName ->
                div
                    [ class "tag" ]
                    [ text tagName
                    , button
                        [ onClick <| closeTagMsg tagName ]
                        [ text "X" ]
                    ]
            )
            tags
        )


{-| Renders markdown if condition is true, otherwise the backup html.
-}
markdownOr : Bool -> String -> Html msg -> Html msg
markdownOr condition markdownText backUpHtml =
    if condition then
        githubMarkdown [] markdownText
    else
        backUpHtml


{-| Builds a progress bar.

NOTE: Progress bar subtracts 1 from current frame, so to get 100% completion
maybeCurrentFrame must be one bigger than maxFrame (eg, 11 / 10). This is done
because we don't wanna count the current frame as complete.
-}
progressBar : Maybe Int -> Int -> Bool -> Html Msg
progressBar maybeCurrentFrame maxFrame isDisabled =
    let
        percentComplete =
            case maybeCurrentFrame of
                Nothing ->
                    0

                Just currentFrame ->
                    if (currentFrame - 1) == 0 then
                        0
                    else
                        100 * (toFloat (currentFrame - 1)) / (toFloat maxFrame)
    in
        div
            [ classList
                [ ( "progress-bar", True )
                , ( "selected", Util.isNotNothing maybeCurrentFrame )
                , ( "disabled", isDisabled )
                ]
            ]
            [ div
                [ classList
                    [ ( "progress-bar-completion-bar", True )
                    , ( "disabled", isDisabled )
                    ]
                , style [ ( "width", (toString <| round <| percentComplete * 1.6) ++ "px" ) ]
                ]
                []
            , div
                [ class "progress-bar-percent" ]
                [ text <| (toString <| round <| percentComplete) ++ "%" ]
            ]


{-| Helper for creating the text above the RHC specifying how many found and
what RHC we are on currently.
-}
relevantHCTextAboveFrameSpecifyingPosition : ( Int, Int ) -> Html msg
relevantHCTextAboveFrameSpecifyingPosition ( current, total ) =
    div
        [ class "above-comment-block-text" ]
        [ if total == 1 then
            text "Only this frame is related to your selection"
          else
            text <| "On frame " ++ (toString current) ++ " of the " ++ (toString total) ++ " frames that are related to your selection"
        ]


{-| Gets the comment box for the view snipbit page, can be the markdown for the
intro/conclusion/frame or the markdown with a few extra buttons for a selected
range.
-}
viewSnipbitCommentBox : Snipbit.Snipbit -> Maybe Model.ViewingSnipbitRelevantHC -> Route.Route -> Html Msg
viewSnipbitCommentBox snipbit relevantHC route =
    let
        -- To display if no relevant HC.
        htmlIfNoRelevantHC =
            githubMarkdown [] <|
                case route of
                    Route.HomeComponentViewSnipbitIntroduction _ ->
                        snipbit.introduction

                    Route.HomeComponentViewSnipbitConclusion _ ->
                        snipbit.conclusion

                    Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                        (Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                        )
                            |> Maybe.map .comment
                            |> Maybe.withDefault ""

                    _ ->
                        ""
    in
        case relevantHC of
            Nothing ->
                htmlIfNoRelevantHC

            Just ({ currentHC, relevantHC } as viewerRelevantHC) ->
                case currentHC of
                    Nothing ->
                        htmlIfNoRelevantHC

                    Just index ->
                        div
                            [ class "view-relevant-hc" ]
                            [ case Model.viewerRelevantHCurrentFramePair viewerRelevantHC of
                                Nothing ->
                                    Util.hiddenDiv

                                Just currentFramePair ->
                                    relevantHCTextAboveFrameSpecifyingPosition currentFramePair
                            , div
                                [ classList
                                    [ ( "above-comment-block-button", True )
                                    , ( "disabled", Model.viewerRelevantHCOnFirstFrame viewerRelevantHC )
                                    ]
                                , onClick ViewSnipbitPreviousRelevantHC
                                ]
                                [ text "Previous" ]
                            , div
                                [ classList
                                    [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                , onClick
                                    (Array.get index relevantHC
                                        |> Maybe.map
                                            (ViewSnipbitJumpToFrame
                                                << Route.HomeComponentViewSnipbitFrame snipbit.id
                                                << ((+) 1)
                                                << Tuple.first
                                            )
                                        |> Maybe.withDefault NoOp
                                    )
                                ]
                                [ text "Jump To Frame" ]
                            , div
                                [ classList
                                    [ ( "above-comment-block-button next-button", True )
                                    , ( "disabled", Model.viewerRelevantHCOnLastFrame viewerRelevantHC )
                                    ]
                                , onClick ViewSnipbitNextRelevantHC
                                ]
                                [ text "Next" ]
                            , githubMarkdown
                                []
                                (Array.get index relevantHC
                                    |> Maybe.map (Tuple.second >> .comment)
                                    |> Maybe.withDefault ""
                                )
                            ]


{-| The view for viewing a snipbit.
-}
viewSnipbitView : Model -> Shared -> Html Msg
viewSnipbitView model shared =
    div
        [ class "view-snipbit" ]
        [ div
            [ class "sub-bar" ]
            [ button
                [ class "sub-bar-button"
                , onClick <| GoTo Route.HomeComponentBrowse
                ]
                [ text "Back" ]
            , button
                [ classList
                    [ ( "sub-bar-button view-relevant-ranges", True )
                    , ( "hidden"
                      , not <|
                            maybeMapWithDefault
                                Model.viewerRelevantHCHasFramesButNotBrowsing
                                False
                                model.viewingSnipbitRelevantHC
                      )
                    ]
                , onClick <| ViewSnipbitBrowseRelevantHC
                ]
                [ text "Browse Related Frames" ]
            , button
                [ classList
                    [ ( "sub-bar-button view-relevant-ranges", True )
                    , ( "hidden"
                      , not <|
                            maybeMapWithDefault
                                Model.viewerRelevantHCBrowsingFrames
                                False
                                model.viewingSnipbitRelevantHC
                      )
                    ]
                , onClick <| ViewSnipbitCancelBrowseRelevantHC
                ]
                [ text "Close Related Frames" ]
            ]
        , case model.viewingSnipbit of
            Nothing ->
                text "LOADING"

            Just snipbit ->
                div
                    [ class "viewer" ]
                    [ div
                        [ class "viewer-navbar" ]
                        [ i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , (case shared.route of
                                        Route.HomeComponentViewSnipbitIntroduction _ ->
                                            True

                                        _ ->
                                            False
                                    )
                                        || (Model.isViewSnipbitRHCTabOpen model)
                                  )
                                ]
                            , onClick <|
                                if (Model.isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.HomeComponentViewSnipbitConclusion mongoID ->
                                            ViewSnipbitJumpToFrame <| Route.HomeComponentViewSnipbitFrame mongoID (Array.length snipbit.highlightedComments)

                                        Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber - 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_back" ]
                        , div
                            [ onClick <|
                                if (Model.isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    GoTo <| Route.HomeComponentViewSnipbitIntroduction snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitIntroduction _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", Model.isViewSnipbitRHCTabOpen model )
                                ]
                            ]
                            [ text "Introduction" ]
                        , progressBar
                            (case shared.route of
                                Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                    Just frameNumber

                                Route.HomeComponentViewSnipbitConclusion _ ->
                                    Just <| Array.length snipbit.highlightedComments + 1

                                _ ->
                                    Nothing
                            )
                            (Array.length snipbit.highlightedComments)
                            (Model.isViewSnipbitRHCTabOpen model)
                        , div
                            [ onClick <|
                                if (Model.isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    GoTo <| Route.HomeComponentViewSnipbitConclusion snipbit.id
                            , classList
                                [ ( "viewer-navbar-item", True )
                                , ( "selected"
                                  , case shared.route of
                                        Route.HomeComponentViewSnipbitConclusion _ ->
                                            True

                                        _ ->
                                            False
                                  )
                                , ( "disabled", Model.isViewSnipbitRHCTabOpen model )
                                ]
                            ]
                            [ text "Conclusion" ]
                        , i
                            [ classList
                                [ ( "material-icons action-button", True )
                                , ( "disabled-icon"
                                  , (case shared.route of
                                        Route.HomeComponentViewSnipbitConclusion _ ->
                                            True

                                        _ ->
                                            False
                                    )
                                        || (Model.isViewSnipbitRHCTabOpen model)
                                  )
                                ]
                            , onClick <|
                                if (Model.isViewSnipbitRHCTabOpen model) then
                                    NoOp
                                else
                                    case shared.route of
                                        Route.HomeComponentViewSnipbitIntroduction mongoID ->
                                            ViewSnipbitJumpToFrame <| Route.HomeComponentViewSnipbitFrame mongoID 1

                                        Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                                            ViewSnipbitJumpToFrame <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber + 1)

                                        _ ->
                                            NoOp
                            ]
                            [ text "arrow_forward" ]
                        ]
                    , Editor.editor "view-snipbit-code-editor"
                    , div
                        [ class "comment-block" ]
                        [ viewSnipbitCommentBox
                            snipbit
                            model.viewingSnipbitRelevantHC
                            shared.route
                        ]
                    ]
        ]


{-| Gets the comment box for the view bigbit page, can be the markdown for the
intro/conclusion/frame, the FS, or the markdown with a few extra buttons for a
selected range.
-}
viewBigbitCommentBox : Bigbit.Bigbit -> Maybe Model.ViewingBigbitRelevantHC -> Route.Route -> Html Msg
viewBigbitCommentBox bigbit maybeRHC route =
    let
        rhcTabOpen =
            isViewBigbitRHCTabOpen maybeRHC

        fsTabOpen =
            isViewBigbitFSTabOpen (Just bigbit) maybeRHC

        tutorialOpen =
            isViewBigbitTutorialTabOpen (Just bigbit) maybeRHC
    in
        div
            [ class "comment-block" ]
            [ div
                [ class "above-editor-text" ]
                [ text <|
                    case Bigbit.viewPageCurrentActiveFile route bigbit of
                        Nothing ->
                            "No File Selected"

                        Just activeFile ->
                            activeFile
                ]
            , githubMarkdown [ hidden <| not <| tutorialOpen ] <|
                case route of
                    Route.HomeComponentViewBigbitIntroduction _ _ ->
                        bigbit.introduction

                    Route.HomeComponentViewBigbitConclusion _ _ ->
                        bigbit.conclusion

                    Route.HomeComponentViewBigbitFrame _ frameNumber _ ->
                        (Array.get
                            (frameNumber - 1)
                            bigbit.highlightedComments
                        )
                            |> Maybe.map .comment
                            |> Maybe.withDefault ""

                    _ ->
                        ""
            , div
                [ class "view-bigbit-fs"
                , hidden <| not <| fsTabOpen
                ]
                [ FS.fileStructure
                    { isFileSelected =
                        (\absolutePath ->
                            Bigbit.viewPageCurrentActiveFile route bigbit
                                |> Maybe.map (FS.isSameFilePath absolutePath)
                                |> Maybe.withDefault False
                        )
                    , fileSelectedMsg = ViewBigbitSelectFile
                    , folderSelectedMsg = ViewBigbitToggleFolder
                    }
                    bigbit.fs
                ]
            , div
                [ class "view-relevant-hc"
                , hidden <| not <| rhcTabOpen
                ]
                (case maybeRHC of
                    Nothing ->
                        [ Util.hiddenDiv ]

                    Just rhc ->
                        case rhc.currentHC of
                            Nothing ->
                                [ Util.hiddenDiv ]

                            Just index ->
                                [ case Model.viewerRelevantHCurrentFramePair rhc of
                                    Nothing ->
                                        Util.hiddenDiv

                                    Just currentFramePair ->
                                        relevantHCTextAboveFrameSpecifyingPosition currentFramePair
                                , githubMarkdown
                                    []
                                    (Array.get index rhc.relevantHC
                                        |> maybeMapWithDefault (Tuple.second >> .comment) ""
                                    )
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button", True )
                                        , ( "disabled", Model.viewerRelevantHCOnFirstFrame rhc )
                                        ]
                                    , onClick ViewBigbitPreviousRelevantHC
                                    ]
                                    [ text "Previous" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button go-to-frame-button", True ) ]
                                    , onClick
                                        (Array.get index rhc.relevantHC
                                            |> maybeMapWithDefault
                                                (ViewBigbitJumpToFrame
                                                    << (\frameNumber ->
                                                            Route.HomeComponentViewBigbitFrame
                                                                bigbit.id
                                                                frameNumber
                                                                Nothing
                                                       )
                                                    << ((+) 1)
                                                    << Tuple.first
                                                )
                                                NoOp
                                        )
                                    ]
                                    [ text "Jump To Frame" ]
                                , div
                                    [ classList
                                        [ ( "above-comment-block-button next-button", True )
                                        , ( "disabled", Model.viewerRelevantHCOnLastFrame rhc )
                                        ]
                                    , onClick ViewBigbitNextRelevantHC
                                    ]
                                    [ text "Next" ]
                                ]
                )
            ]


{-| The view for viewing a bigbit.
-}
viewBigbitView : Model -> Shared -> Html Msg
viewBigbitView model shared =
    let
        -- They can be on the FS or browsing RHC.
        notGoingThroughTutorial =
            not <| isViewBigbitTutorialTabOpen model.viewingBigbit model.viewingBigbitRelevantHC
    in
        div
            [ class "view-bigbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "sub-bar-button"
                    , onClick <| GoTo Route.HomeComponentBrowse
                    ]
                    [ text "Back" ]
                , button
                    [ classList
                        [ ( "sub-bar-button explore-fs", True )
                        , ( "hidden"
                          , (isViewBigbitRHCTabOpen model.viewingBigbitRelevantHC)
                                && (not <| isViewBigbitFSOpen model.viewingBigbit)
                          )
                        ]
                    , onClick <| ViewBigbitToggleFS
                    ]
                    [ text <|
                        if isViewBigbitFSOpen model.viewingBigbit then
                            "Resume Tutorial"
                        else
                            "Explore File Structure"
                    ]
                , button
                    [ classList
                        [ ( "sub-bar-button view-relevant-ranges", True )
                        , ( "hidden"
                          , not <|
                                maybeMapWithDefault
                                    Model.viewerRelevantHCHasFramesButNotBrowsing
                                    False
                                    model.viewingBigbitRelevantHC
                          )
                        ]
                    , onClick ViewBigbitBrowseRelevantHC
                    ]
                    [ text "Browse Related Frames" ]
                , button
                    [ classList
                        [ ( "sub-bar-button view-relevant-ranges", True )
                        , ( "hidden"
                          , not <|
                                maybeMapWithDefault
                                    Model.viewerRelevantHCBrowsingFrames
                                    False
                                    model.viewingBigbitRelevantHC
                          )
                        ]
                    , onClick ViewBigbitCancelBrowseRelevantHC
                    ]
                    [ text "Close Related Frames" ]
                ]
            , case model.viewingBigbit of
                Nothing ->
                    div
                        []
                        [ text "LOADING" ]

                Just bigbit ->
                    div
                        [ class "viewer" ]
                        [ div
                            [ class "viewer-navbar" ]
                            [ i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon"
                                      , if notGoingThroughTutorial then
                                            True
                                        else
                                            case shared.route of
                                                Route.HomeComponentViewBigbitIntroduction _ _ ->
                                                    True

                                                _ ->
                                                    False
                                      )
                                    ]
                                , onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        case shared.route of
                                            Route.HomeComponentViewBigbitConclusion mongoID _ ->
                                                ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitFrame mongoID (Array.length bigbit.highlightedComments) Nothing

                                            Route.HomeComponentViewBigbitFrame mongoID frameNumber _ ->
                                                ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber - 1) Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_back" ]
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitIntroduction bigbit.id Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.HomeComponentViewBigbitIntroduction _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", notGoingThroughTutorial )
                                    ]
                                ]
                                [ text "Introduction" ]
                            , progressBar
                                (case shared.route of
                                    Route.HomeComponentViewBigbitFrame _ frameNumber _ ->
                                        Just frameNumber

                                    Route.HomeComponentViewBigbitConclusion _ _ ->
                                        Just <| Array.length bigbit.highlightedComments + 1

                                    _ ->
                                        Nothing
                                )
                                (Array.length bigbit.highlightedComments)
                                notGoingThroughTutorial
                            , div
                                [ onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitConclusion bigbit.id Nothing
                                , classList
                                    [ ( "viewer-navbar-item", True )
                                    , ( "selected"
                                      , case shared.route of
                                            Route.HomeComponentViewBigbitConclusion _ _ ->
                                                True

                                            _ ->
                                                False
                                      )
                                    , ( "disabled", notGoingThroughTutorial )
                                    ]
                                ]
                                [ text "Conclusion" ]
                            , i
                                [ classList
                                    [ ( "material-icons action-button", True )
                                    , ( "disabled-icon"
                                      , if notGoingThroughTutorial then
                                            True
                                        else
                                            case shared.route of
                                                Route.HomeComponentViewBigbitConclusion _ _ ->
                                                    True

                                                _ ->
                                                    False
                                      )
                                    ]
                                , onClick <|
                                    if notGoingThroughTutorial then
                                        NoOp
                                    else
                                        case shared.route of
                                            Route.HomeComponentViewBigbitIntroduction mongoID _ ->
                                                ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitFrame mongoID 1 Nothing

                                            Route.HomeComponentViewBigbitFrame mongoID frameNumber _ ->
                                                ViewBigbitJumpToFrame <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber + 1) Nothing

                                            _ ->
                                                NoOp
                                ]
                                [ text "arrow_forward" ]
                            ]
                        , Editor.editor "view-bigbit-code-editor"
                        , viewBigbitCommentBox bigbit model.viewingBigbitRelevantHC shared.route
                        ]
            ]


{-| Displays the correct view based on the model.
-}
displayViewForRoute : Model -> Shared -> Html Msg
displayViewForRoute model shared =
    case shared.route of
        Route.HomeComponentBrowse ->
            browseView model

        Route.HomeComponentViewSnipbitIntroduction _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewSnipbitConclusion _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewSnipbitFrame _ _ ->
            viewSnipbitView model shared

        Route.HomeComponentViewBigbitIntroduction _ _ ->
            viewBigbitView model shared

        Route.HomeComponentViewBigbitFrame _ _ _ ->
            viewBigbitView model shared

        Route.HomeComponentViewBigbitConclusion _ _ ->
            viewBigbitView model shared

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

        Route.HomeComponentCreateBigbitName ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitDescription ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitTags ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeIntroduction _ ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeFrame _ _ ->
            createBigbitView model shared

        Route.HomeComponentCreateBigbitCodeConclusion _ ->
            createBigbitView model shared

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
            case shared.route of
                Route.HomeComponentBrowse ->
                    True

                Route.HomeComponentViewSnipbitIntroduction _ ->
                    True

                Route.HomeComponentViewSnipbitFrame _ _ ->
                    True

                Route.HomeComponentViewSnipbitConclusion _ ->
                    True

                Route.HomeComponentViewBigbitIntroduction _ _ ->
                    True

                Route.HomeComponentViewBigbitFrame _ _ _ ->
                    True

                Route.HomeComponentViewBigbitConclusion _ _ ->
                    True

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.HomeComponentProfile

        createViewSelected =
            case shared.route of
                Route.HomeComponentCreateSnipbitCodeFrame _ ->
                    True

                Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                    True

                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                    True

                Route.HomeComponentCreateBigbitCodeConclusion _ ->
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
                        , Route.HomeComponentCreateBigbitName
                        , Route.HomeComponentCreateBigbitDescription
                        , Route.HomeComponentCreateBigbitTags
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
            """BigBits are multi-language projects of code targetted at
            simplifying larger tutorials which require their own file structure.

            You highlight chunks of code and attach comments automatically
            taking your user through all the files and folders in a directed
            fashion while still letting them explore themselves.
            """

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
                        (GoTo Route.HomeComponentCreateBigbitName)
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


{-| View for creating a bigbit.
-}
createBigbitView : Model -> Shared -> Html Msg
createBigbitView model shared =
    let
        currentRoute =
            shared.route

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Bigbit.createDataToPublicationData model.bigbitCreateData of
                Nothing ->
                    button
                        [ class "create-bigbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just bigbitForPublicaton ->
                    button
                        [ class "create-bigbit-publish-button"
                        , onClick <| BigbitPublish bigbitForPublicaton
                        ]
                        [ text "Publish" ]

        createBigbitNavbar : Html Msg
        createBigbitNavbar =
            div
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitName
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataNameFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitName
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitDescription
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataDescriptionFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitDescription
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateBigbitTags
                          )
                        , ( "filled-in", Util.isNotNothing <| Bigbit.createDataTagsFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateBigbitTags
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , case currentRoute of
                                Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                                    True

                                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                                    True

                                Route.HomeComponentCreateBigbitCodeConclusion _ ->
                                    True

                                _ ->
                                    False
                          )
                        , ( "filled-in", Bigbit.createDataCodeTabFilledIn model.bigbitCreateData )
                        ]
                    , onClick <| BigbitGoToCodeTab
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        bigbitCodeTab =
            let
                currentActiveFile =
                    Bigbit.createPageCurrentActiveFile shared.route

                viewingFile absolutePath =
                    Maybe.map (FS.isSameFilePath absolutePath) currentActiveFile
                        |> Maybe.withDefault False

                ( introTab, conclusionTab, frameTab ) =
                    case shared.route of
                        Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                            ( True, False, Nothing )

                        Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                            ( False, False, Just frameNumber )

                        Route.HomeComponentCreateBigbitCodeConclusion _ ->
                            ( False, True, Nothing )

                        _ ->
                            ( False, False, Nothing )

                bigbitEditor =
                    div
                        [ class "bigbit-editor" ]
                        [ div
                            [ class "current-file" ]
                            [ text <|
                                if introTab then
                                    "Bigbit introductions do not link to files or highlights, but you can browse and edit your code"
                                else if conclusionTab then
                                    "Bigbit conclusions do not link to files or highlights, but you can browse and edit your code"
                                else
                                    Maybe.withDefault "No File Selected" currentActiveFile
                            ]
                        , div
                            [ class "create-tidbit-code" ]
                            [ Editor.editor "create-bigbit-code-editor"
                            ]
                        ]

                bigbitCommentBox =
                    let
                        fsMetadata =
                            FS.getFSMetadata <| model.bigbitCreateData.fs

                        maybeActionState =
                            fsMetadata.actionButtonState

                        actionInput =
                            fsMetadata.actionButtonInput

                        validFileInputResult =
                            Bigbit.isValidAddFileInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFileInput =
                            Util.resultToBool validFileInputResult

                        validRemoveFileInputResult =
                            Bigbit.isValidRemoveFileInput actionInput model.bigbitCreateData.fs

                        validRemoveFileInput =
                            Util.resultToBool validRemoveFileInputResult

                        validRemoveFolderInputResult =
                            Bigbit.isValidRemoveFolderInput actionInput model.bigbitCreateData.fs

                        validRemoveFolderInput =
                            Util.resultToBool validRemoveFolderInputResult

                        validFolderInputResult =
                            Bigbit.isValidAddFolderInput
                                actionInput
                                model.bigbitCreateData.fs

                        validFolderInput =
                            Util.resultToBool validFolderInputResult

                        fsOpen =
                            Bigbit.isFSOpen model.bigbitCreateData.fs

                        markdownOpen =
                            model.bigbitCreateData.previewMarkdown

                        fs =
                            div
                                [ class "file-structure"
                                , hidden <| not <| fsOpen
                                ]
                                [ FS.fileStructure
                                    { isFileSelected = viewingFile
                                    , fileSelectedMsg = BigbitFileSelected
                                    , folderSelectedMsg = BigbitFSToggleFolder
                                    }
                                    model.bigbitCreateData.fs
                                , div
                                    [ class "fs-action-input"
                                    , hidden <| Util.isNothing <| maybeActionState
                                    ]
                                    [ div
                                        [ class "fs-action-input-text" ]
                                        [ case maybeActionState of
                                            Nothing ->
                                                Util.hiddenDiv

                                            Just actionState ->
                                                case actionState of
                                                    Bigbit.AddingFolder ->
                                                        case validFolderInputResult of
                                                            Ok _ ->
                                                                text "Create folder and parent directories"

                                                            Err err ->
                                                                text <|
                                                                    case err of
                                                                        Bigbit.FolderAlreadyExists ->
                                                                            "That folder already exists"

                                                                        Bigbit.FolderHasDoubleSlash ->
                                                                            "You cannot have two slashes in a row"

                                                                        Bigbit.FolderHasInvalidCharacters ->
                                                                            "You are using invalid characters"

                                                                        Bigbit.FolderIsEmpty ->
                                                                            ""

                                                    Bigbit.AddingFile ->
                                                        case validFileInputResult of
                                                            Ok _ ->
                                                                text "Create file and parent directories"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.FileAlreadyExists ->
                                                                        text "That file already exists"

                                                                    Bigbit.FileEndsInSlash ->
                                                                        text "Files cannot end in a slash"

                                                                    Bigbit.FileHasDoubleSlash ->
                                                                        text "You cannot have two slashes in a row"

                                                                    Bigbit.FileHasInvalidCharacters ->
                                                                        text "You are using invalid characters"

                                                                    Bigbit.FileHasInvalidExtension ->
                                                                        text "You must have a valid file extension"

                                                                    Bigbit.FileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.FileLanguageIsAmbiguous languages ->
                                                                        div
                                                                            [ class "fs-action-input-select-language-text" ]
                                                                            [ text "Select language to create file: "
                                                                            , div
                                                                                [ class "language-options" ]
                                                                                (languages
                                                                                    |> List.sortBy toString
                                                                                    |> List.map
                                                                                        (\language ->
                                                                                            button
                                                                                                [ onClick <| BigbitAddFile actionInput language ]
                                                                                                [ text <| toString language ]
                                                                                        )
                                                                                )
                                                                            ]

                                                    Bigbit.RemovingFolder ->
                                                        case validRemoveFolderInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove folder"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFolderIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFolderIsRootFolder ->
                                                                        text "You cannot remove the root directory"

                                                                    Bigbit.RemoveFolderDoesNotExist ->
                                                                        text "Folder doesn't exist"

                                                    Bigbit.RemovingFile ->
                                                        case validRemoveFileInputResult of
                                                            Ok _ ->
                                                                if .actionButtonSubmitConfirmed <| FS.getFSMetadata model.bigbitCreateData.fs then
                                                                    text "Are you sure? This will also delete all linked frames!"
                                                                else
                                                                    text "Remove file"

                                                            Err err ->
                                                                case err of
                                                                    Bigbit.RemoveFileIsEmpty ->
                                                                        text ""

                                                                    Bigbit.RemoveFileDoesNotExist ->
                                                                        text "File doesn't exist"
                                        ]
                                    , input
                                        [ id "fs-action-input-box"
                                        , placeholder "Absolute Path"
                                        , onInput BigbitUpdateActionInput
                                        , Util.onKeydown
                                            (\key ->
                                                if key == KK.Enter then
                                                    Just BigbitSubmitActionInput
                                                else
                                                    Nothing
                                            )
                                        , value
                                            (model.bigbitCreateData.fs
                                                |> FS.getFSMetadata
                                                |> .actionButtonInput
                                            )
                                        ]
                                        []
                                    , case maybeActionState of
                                        Nothing ->
                                            Util.hiddenDiv

                                        Just actionState ->
                                            let
                                                showSubmitIconIf condition isPlus =
                                                    if condition then
                                                        i
                                                            [ classList
                                                                [ ( "material-icons action-button-submit-icon", True )
                                                                , ( "arrow-confirmed"
                                                                  , model.bigbitCreateData.fs
                                                                        |> FS.getFSMetadata
                                                                        |> .actionButtonSubmitConfirmed
                                                                  )
                                                                ]
                                                            , onClick <| BigbitSubmitActionInput
                                                            ]
                                                            [ text <|
                                                                if isPlus then
                                                                    "add_box"
                                                                else
                                                                    "indeterminate_check_box"
                                                            ]
                                                    else
                                                        Util.hiddenDiv
                                            in
                                                case actionState of
                                                    Bigbit.AddingFile ->
                                                        showSubmitIconIf validFileInput True

                                                    Bigbit.AddingFolder ->
                                                        showSubmitIconIf validFolderInput True

                                                    Bigbit.RemovingFile ->
                                                        showSubmitIconIf validRemoveFileInput False

                                                    Bigbit.RemovingFolder ->
                                                        showSubmitIconIf validRemoveFolderInput False
                                    ]
                                , button
                                    [ classList
                                        [ ( "add-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFile
                                    ]
                                    [ text "Add File" ]
                                , button
                                    [ classList
                                        [ ( "add-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.AddingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.AddingFolder
                                    ]
                                    [ text "Add Folder" ]
                                , button
                                    [ classList
                                        [ ( "remove-file", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFile) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFile
                                    ]
                                    [ text "Remove File" ]
                                , button
                                    [ classList
                                        [ ( "remove-folder", True )
                                        , ( "selected-action-button"
                                          , Bigbit.fsActionStateEquals (Just Bigbit.RemovingFolder) model.bigbitCreateData.fs
                                          )
                                        ]
                                    , onClick <| BigbitUpdateActionButtonState <| Just Bigbit.RemovingFolder
                                    ]
                                    [ text "Remove Folder" ]
                                ]

                        body =
                            div
                                [ class "comment-body" ]
                                [ fs
                                , div
                                    [ class "expand-file-structure"
                                    , onClick BigbitToggleFS
                                    , hidden markdownOpen
                                    ]
                                    [ if fsOpen then
                                        text "Close File Structure"
                                      else
                                        text "View File Structure"
                                    ]
                                , div
                                    [ class "preview-markdown"
                                    , onClick BigbitTogglePreviewMarkdown
                                    , hidden fsOpen
                                    ]
                                    [ if markdownOpen then
                                        text "Close Preview"
                                      else
                                        text "Preview Markdown"
                                    ]
                                , case shared.route of
                                    Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                                        markdownOr
                                            markdownOpen
                                            model.bigbitCreateData.introduction
                                            (textarea
                                                [ placeholder "Introduction"
                                                , id "introduction-input"
                                                , onInput <| BigbitUpdateIntroduction
                                                , hidden <| Bigbit.isFSOpen model.bigbitCreateData.fs
                                                , value model.bigbitCreateData.introduction
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.HomeComponentCreateBigbitCodeFrame
                                                                                1
                                                                                (Bigbit.createPageGetActiveFileForFrame 1 model.bigbitCreateData)
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <| GoTo <| Route.HomeComponentCreateBigbitTags
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
                                            )

                                    Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                                        let
                                            frameText =
                                                (Array.get
                                                    (frameNumber - 1)
                                                    model.bigbitCreateData.highlightedComments
                                                )
                                                    |> Maybe.map .comment
                                                    |> Maybe.withDefault ""
                                        in
                                            markdownOr
                                                markdownOpen
                                                frameText
                                                (textarea
                                                    [ placeholder <| "Frame " ++ (toString frameNumber)
                                                    , id "frame-input"
                                                    , onInput <| BigbitUpdateFrameComment frameNumber
                                                    , value frameText
                                                    , hidden <| fsOpen
                                                    , Util.onKeydownPreventDefault
                                                        (\key ->
                                                            let
                                                                newKeysDown =
                                                                    kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                            in
                                                                if key == KK.Tab then
                                                                    if newKeysDown == shared.keysDown then
                                                                        Just NoOp
                                                                    else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.HomeComponentCreateBigbitCodeFrame
                                                                                    (frameNumber + 1)
                                                                                    (Bigbit.createPageGetActiveFileForFrame
                                                                                        (frameNumber + 1)
                                                                                        model.bigbitCreateData
                                                                                    )
                                                                    else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                        Just <|
                                                                            GoTo <|
                                                                                Route.HomeComponentCreateBigbitCodeFrame
                                                                                    (frameNumber - 1)
                                                                                    (Bigbit.createPageGetActiveFileForFrame
                                                                                        (frameNumber - 1)
                                                                                        model.bigbitCreateData
                                                                                    )
                                                                    else
                                                                        Nothing
                                                                else
                                                                    Nothing
                                                        )
                                                    ]
                                                    []
                                                )

                                    Route.HomeComponentCreateBigbitCodeConclusion _ ->
                                        markdownOr
                                            markdownOpen
                                            model.bigbitCreateData.conclusion
                                            (textarea
                                                [ placeholder "Conclusion"
                                                , id "conclusion-input"
                                                , onInput BigbitUpdateConclusion
                                                , hidden <| fsOpen
                                                , value model.bigbitCreateData.conclusion
                                                , Util.onKeydownPreventDefault
                                                    (\key ->
                                                        let
                                                            newKeysDown =
                                                                kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                        in
                                                            if key == KK.Tab then
                                                                if newKeysDown == shared.keysDown then
                                                                    Just NoOp
                                                                else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                    Just <| NoOp
                                                                else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                    Just <|
                                                                        GoTo <|
                                                                            Route.HomeComponentCreateBigbitCodeFrame
                                                                                (Array.length model.bigbitCreateData.highlightedComments)
                                                                                (Bigbit.createPageGetActiveFileForFrame
                                                                                    (Array.length model.bigbitCreateData.highlightedComments)
                                                                                    model.bigbitCreateData
                                                                                )
                                                                else
                                                                    Nothing
                                                            else
                                                                Nothing
                                                    )
                                                ]
                                                []
                                            )

                                    _ ->
                                        -- Should never happen.
                                        Util.hiddenDiv
                                ]

                        tabBar =
                            let
                                dynamicFrameButtons =
                                    div
                                        [ class "frame-buttons-box" ]
                                        ((Array.indexedMap
                                            (\index highlightedComment ->
                                                button
                                                    [ classList [ ( "selected-frame", (Just <| index + 1) == frameTab ) ]
                                                    , onClick <|
                                                        GoTo <|
                                                            Route.HomeComponentCreateBigbitCodeFrame
                                                                (index + 1)
                                                                (Bigbit.createPageGetActiveFileForFrame
                                                                    (index + 1)
                                                                    model.bigbitCreateData
                                                                )
                                                    ]
                                                    [ text <| toString <| index + 1 ]
                                            )
                                            model.bigbitCreateData.highlightedComments
                                         )
                                            |> Array.toList
                                        )
                            in
                                div
                                    [ class "comment-body-bottom-buttons"
                                    , hidden <| fsOpen || markdownOpen
                                    ]
                                    [ button
                                        [ onClick <| GoTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing
                                        , classList
                                            [ ( "introduction-button", True )
                                            , ( "selected-frame", introTab )
                                            ]
                                        ]
                                        [ text "Introduction" ]
                                    , button
                                        [ onClick <| GoTo <| Route.HomeComponentCreateBigbitCodeConclusion Nothing
                                        , classList
                                            [ ( "conclusion-button", True )
                                            , ( "selected-frame", conclusionTab )
                                            ]
                                        ]
                                        [ text "Conclusion" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitAddFrame
                                        ]
                                        [ text "+" ]
                                    , button
                                        [ class "add-or-remove-frame-button"
                                        , onClick <| BigbitRemoveFrame
                                        , disabled <|
                                            Array.length model.bigbitCreateData.highlightedComments
                                                <= 1
                                        ]
                                        [ text "-" ]
                                    , hr [] []
                                    , dynamicFrameButtons
                                    ]
                    in
                        div
                            []
                            [ div
                                [ class "comment-creator" ]
                                [ body
                                , tabBar
                                ]
                            ]
            in
                div
                    [ class "create-bigbit-code" ]
                    [ bigbitEditor
                    , bigbitCommentBox
                    ]
    in
        div
            [ class "create-bigbit" ]
            [ div
                [ class "sub-bar" ]
                [ button
                    [ class "sub-bar-button"
                    , onClick <| GoTo Route.HomeComponentCreate
                    ]
                    [ text "Back" ]
                , button
                    [ class "sub-bar-button"
                    , onClick <| BigbitReset
                    ]
                    [ text "Reset" ]
                , case Bigbit.previousFrameLocation model.bigbitCreateData shared.route of
                    Nothing ->
                        Util.hiddenDiv

                    Just ( filePath, _ ) ->
                        button
                            [ class "sub-bar-button previous-frame-location"
                            , onClick <| BigbitJumpToLineFromPreviousFrame filePath
                            ]
                            [ text "Previous Frame Location" ]
                , publishButton
                ]
            , createBigbitNavbar
            , case shared.route of
                Route.HomeComponentCreateBigbitName ->
                    div
                        [ class "create-bigbit-name" ]
                        [ input
                            [ placeholder "Name"
                            , id "name-input"
                            , onInput BigbitUpdateName
                            , value model.bigbitCreateData.name
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.HomeComponentCreateBigbitDescription ->
                    div
                        [ class "create-bigbit-description" ]
                        [ textarea
                            [ placeholder "Description"
                            , id "description-input"
                            , onInput BigbitUpdateDescription
                            , value model.bigbitCreateData.description
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Tab then
                                        Just NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        ]

                Route.HomeComponentCreateBigbitTags ->
                    div
                        [ class "create-tidbit-tags" ]
                        [ input
                            [ placeholder "Tags"
                            , id "tags-input"
                            , onInput BigbitUpdateTagInput
                            , value model.bigbitCreateData.tagInput
                            , Util.onKeydownPreventDefault
                                (\key ->
                                    if key == KK.Enter then
                                        Just <| BigbitAddTag model.bigbitCreateData.tagInput
                                    else if key == KK.Tab then
                                        Just <| NoOp
                                    else
                                        Nothing
                                )
                            ]
                            []
                        , makeHTMLTags BigbitRemoveTag model.bigbitCreateData.tags
                        ]

                Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeFrame frameNumber _ ->
                    bigbitCodeTab

                Route.HomeComponentCreateBigbitCodeConclusion _ ->
                    bigbitCodeTab

                -- Should never happen
                _ ->
                    div [] []
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
                      , String.isEmpty model.snipbitCreateData.languageQuery
                            || Util.isNotNothing
                                model.snipbitCreateData.language
                      )
                    ]
                ]
                [ Html.map
                    SnipbitUpdateACState
                    (AC.view
                        acViewConfig
                        model.snipbitCreateData.languageListHowManyToShow
                        model.snipbitCreateData.languageQueryACState
                        (filterLanguagesByQuery
                            model.snipbitCreateData.languageQuery
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
                [ classList [ ( "create-tidbit-navbar", True ) ] ]
                [ div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitName
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataNameFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitName
                    ]
                    [ text "Name"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitDescription
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataDescriptionFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitDescription
                    ]
                    [ text "Description"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitLanguage
                          )
                        , ( "filled-in", Util.isNotNothing <| model.snipbitCreateData.language )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitLanguage
                    ]
                    [ text "Language"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
                          , currentRoute == Route.HomeComponentCreateSnipbitTags
                          )
                        , ( "filled-in", Util.isNotNothing <| Snipbit.createDataTagsFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| GoTo Route.HomeComponentCreateSnipbitTags
                    ]
                    [ text "Tags"
                    , checkIcon
                    ]
                , div
                    [ classList
                        [ ( "create-tidbit-tab", True )
                        , ( "create-tidbit-selected-tab"
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
                        , ( "filled-in", Snipbit.createDataCodeTabFilledIn model.snipbitCreateData )
                        ]
                    , onClick <| SnipbitGoToCodeTab
                    ]
                    [ text "Code"
                    , checkIcon
                    ]
                ]

        nameView : Html Msg
        nameView =
            div
                [ class "create-snipbit-name" ]
                [ input
                    [ placeholder "Name"
                    , id "name-input"
                    , onInput SnipbitUpdateName
                    , value model.snipbitCreateData.name
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
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
                    , id "description-input"
                    , onInput SnipbitUpdateDescription
                    , value model.snipbitCreateData.description
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
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
                    , value model.snipbitCreateData.languageQuery
                    , disabled <|
                        Util.isNotNothing
                            model.snipbitCreateData.language
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Tab then
                                Just NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                , viewMenu
                , button
                    [ onClick <| SnipbitSelectLanguage Nothing
                    , classList
                        [ ( "hidden"
                          , Util.isNothing
                                model.snipbitCreateData.language
                          )
                        ]
                    ]
                    [ text "change language" ]
                ]

        tagsView : Html Msg
        tagsView =
            div
                [ class "create-tidbit-tags" ]
                [ input
                    [ placeholder "Tags"
                    , id "tags-input"
                    , onInput SnipbitUpdateTagInput
                    , value model.snipbitCreateData.tagInput
                    , Util.onKeydownPreventDefault
                        (\key ->
                            if key == KK.Enter then
                                Just <| SnipbitAddTag model.snipbitCreateData.tagInput
                            else if key == KK.Tab then
                                Just <| NoOp
                            else
                                Nothing
                        )
                    ]
                    []
                , makeHTMLTags SnipbitRemoveTag model.snipbitCreateData.tags
                ]

        tidbitView : Html Msg
        tidbitView =
            let
                markdownOpen =
                    model.snipbitCreateData.previewMarkdown

                body =
                    div
                        [ class "comment-body" ]
                        [ div
                            [ class "preview-markdown"
                            , onClick SnipbitTogglePreviewMarkdown
                            ]
                            [ if markdownOpen then
                                text "Close Preview"
                              else
                                text "Markdown Preview"
                            ]
                        , case shared.route of
                            Route.HomeComponentCreateSnipbitCodeIntroduction ->
                                markdownOr
                                    markdownOpen
                                    model.snipbitCreateData.introduction
                                    (textarea
                                        [ placeholder "Introduction"
                                        , id "introduction-input"
                                        , onInput <| SnipbitUpdateIntroduction
                                        , value model.snipbitCreateData.introduction
                                        , Util.onKeydownPreventDefault
                                            (\key ->
                                                let
                                                    newKeysDown =
                                                        kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                in
                                                    if key == KK.Tab then
                                                        if newKeysDown == shared.keysDown then
                                                            Just NoOp
                                                        else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                            Just <| GoTo <| Route.HomeComponentCreateSnipbitCodeFrame 1
                                                        else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                            Just <| GoTo <| Route.HomeComponentCreateSnipbitTags
                                                        else
                                                            Nothing
                                                    else
                                                        Nothing
                                            )
                                        ]
                                        []
                                    )

                            Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                                let
                                    frameIndex =
                                        frameNumber - 1

                                    frameText =
                                        (Array.get
                                            frameIndex
                                            model.snipbitCreateData.highlightedComments
                                        )
                                            |> Maybe.andThen .comment
                                            |> Maybe.withDefault ""
                                in
                                    markdownOr
                                        markdownOpen
                                        frameText
                                        (textarea
                                            [ placeholder <|
                                                "Frame "
                                                    ++ (toString frameNumber)
                                            , id "frame-input"
                                            , onInput <|
                                                SnipbitUpdateFrameComment frameIndex
                                            , value <| frameText
                                            , Util.onKeydownPreventDefault
                                                (\key ->
                                                    let
                                                        newKeysDown =
                                                            kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                    in
                                                        if key == KK.Tab then
                                                            if newKeysDown == shared.keysDown then
                                                                Just NoOp
                                                            else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                                Just <| GoTo <| Route.HomeComponentCreateSnipbitCodeFrame (frameNumber + 1)
                                                            else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                                Just <| GoTo <| Route.HomeComponentCreateSnipbitCodeFrame (frameNumber - 1)
                                                            else
                                                                Nothing
                                                        else
                                                            Nothing
                                                )
                                            ]
                                            []
                                        )

                            Route.HomeComponentCreateSnipbitCodeConclusion ->
                                markdownOr
                                    markdownOpen
                                    model.snipbitCreateData.conclusion
                                    (textarea
                                        [ placeholder "Conclusion"
                                        , id "conclusion-input"
                                        , onInput <| SnipbitUpdateConclusion
                                        , value model.snipbitCreateData.conclusion
                                        , Util.onKeydownPreventDefault
                                            (\key ->
                                                let
                                                    newKeysDown =
                                                        kkUpdateWrapper (KK.Down <| KK.toCode key) shared.keysDown
                                                in
                                                    if key == KK.Tab then
                                                        if newKeysDown == shared.keysDown then
                                                            Just NoOp
                                                        else if KK.isOneKeyPressed KK.Tab newKeysDown then
                                                            Just NoOp
                                                        else if KK.isTwoKeysPressed KK.Tab KK.Shift newKeysDown then
                                                            Just <|
                                                                GoTo <|
                                                                    Route.HomeComponentCreateSnipbitCodeFrame
                                                                        (Array.length model.snipbitCreateData.highlightedComments)
                                                        else
                                                            Nothing
                                                    else
                                                        Nothing
                                            )
                                        ]
                                        []
                                    )

                            -- Should never happen.
                            _ ->
                                div
                                    []
                                    []
                        ]

                tabBar =
                    let
                        dynamicFrameButtons =
                            div
                                [ class "frame-buttons-box" ]
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
                                        model.snipbitCreateData.highlightedComments
                                )
                    in
                        div
                            [ class "comment-body-bottom-buttons"
                            , hidden <| markdownOpen
                            ]
                            [ button
                                [ onClick <|
                                    GoTo Route.HomeComponentCreateSnipbitCodeIntroduction
                                , classList
                                    [ ( "selected-frame"
                                      , shared.route
                                            == Route.HomeComponentCreateSnipbitCodeIntroduction
                                      )
                                    , ( "introduction-button", True )
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
                                    , ( "conclusion-button", True )
                                    ]
                                ]
                                [ text "Conclusion" ]
                            , button
                                [ class "add-or-remove-frame-button"
                                , onClick <| SnipbitAddFrame
                                ]
                                [ text "+" ]
                            , button
                                [ class "add-or-remove-frame-button"
                                , onClick <| SnipbitRemoveFrame
                                , disabled <|
                                    Array.length
                                        model.snipbitCreateData.highlightedComments
                                        <= 1
                                ]
                                [ text "-" ]
                            , hr [] []
                            , dynamicFrameButtons
                            ]
            in
                div
                    [ class "create-snipbit-code" ]
                    [ Editor.editor "create-snipbit-code-editor"
                    , div
                        [ class "comment-creator" ]
                        [ div
                            [ class "above-editor-text" ]
                            [ text <|
                                if currentRoute == Route.HomeComponentCreateSnipbitCodeIntroduction then
                                    "Snipbit introductions do not link to highlights, but you can browse and edit your code"
                                else if currentRoute == Route.HomeComponentCreateSnipbitCodeConclusion then
                                    "Snipbit conclusions do not link to highlights, but you can browse and edit your code"
                                else
                                    ""
                            ]
                        , body
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

        {- It should be disabled unles everything is filled out. -}
        publishButton =
            case Snipbit.createDataToPublicationData model.snipbitCreateData of
                Nothing ->
                    button
                        [ class "create-snipbit-disabled-publish-button"
                        , disabled True
                        ]
                        [ text "Publish" ]

                Just publicationData ->
                    button
                        [ classList
                            [ ( "create-snipbit-publish-button", True )
                            ]
                        , onClick <| SnipbitPublish publicationData
                        ]
                        [ text "Publish" ]
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
                , publishButton
                , case Snipbit.previousFrameLocation model.snipbitCreateData shared.route of
                    Nothing ->
                        Util.hiddenDiv

                    Just _ ->
                        button
                            [ class "sub-bar-button previous-frame-location"
                            , onClick SnipbitJumpToLineFromPreviousFrame
                            ]
                            [ text "Previous Frame Location" ]
                ]
            , div
                []
                [ createSnipbitNavbar
                , viewForTab
                ]
            ]
