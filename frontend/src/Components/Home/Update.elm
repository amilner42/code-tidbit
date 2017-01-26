module Components.Home.Update exposing (update, filterLanguagesByQuery)

import Array
import Api
import Autocomplete as AC
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import Dom
import DefaultModel exposing (defaultShared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Json.Decode as Decode
import Models.Snipbit as Snipbit
import Models.Route as Route
import Router
import Task
import Ports


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        updateSnipbitCreateData : Snipbit.SnipbitCreateData -> Model
        updateSnipbitCreateData newCreatingSnipbitData =
            { model
                | creatingSnipbitData = newCreatingSnipbitData
            }

        currentCreatingSnipbitData : Snipbit.SnipbitCreateData
        currentCreatingSnipbitData =
            model.creatingSnipbitData

        currentHighlightedComments =
            currentCreatingSnipbitData.highlightedComments
    in
        case msg of
            NoOp ->
                doNothing

            -- Recieves route hits from the router and handles the logic of the
            -- route hooks.
            OnRouteHit ->
                let
                    getSnipbit mongoID =
                        ( { model
                            | viewingSnipbit = Nothing
                          }
                        , shared
                        , Api.getSnipbit mongoID OnGetSnipbitFailure OnGetSnipbitSuccess
                        )

                    renderSnipbit codeEditorConfig =
                        ( model
                        , shared
                        , Ports.createCodeEditor codeEditorConfig
                        )

                    -- TODO get user theme.
                    userTheme =
                        ""
                in
                    case shared.route of
                        Route.HomeComponentViewSnipbitIntroduction mongoID ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        renderSnipbit
                                            { id = "view-snipbit-code-editor"
                                            , lang = Editor.aceLanguageLocation aSnipbit.language
                                            , theme = userTheme
                                            , value = aSnipbit.code
                                            , range = Nothing
                                            , readOnly = True
                                            }
                                    else
                                        getSnipbit mongoID

                        Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        -- Make sure frame is in range, if not
                                        -- redirect to intro/conclusion depending
                                        -- on if it's beneath/above range respectively.
                                        if frameNumber - 1 >= Array.length aSnipbit.highlightedComments then
                                            ( model
                                            , shared
                                            , Router.navigateTo <|
                                                Route.HomeComponentViewSnipbitConclusion mongoID
                                            )
                                        else if frameNumber < 1 then
                                            ( model
                                            , shared
                                            , Router.navigateTo <|
                                                Route.HomeComponentViewSnipbitIntroduction mongoID
                                            )
                                        else
                                            renderSnipbit
                                                { id = "view-snipbit-code-editor"
                                                , lang = Editor.aceLanguageLocation aSnipbit.language
                                                , theme = userTheme
                                                , value = aSnipbit.code
                                                , range =
                                                    Array.get
                                                        (frameNumber - 1)
                                                        aSnipbit.highlightedComments
                                                        |> Maybe.map .range
                                                , readOnly = True
                                                }
                                    else
                                        getSnipbit mongoID

                        Route.HomeComponentViewSnipbitConclusion mongoID ->
                            case model.viewingSnipbit of
                                Nothing ->
                                    getSnipbit mongoID

                                Just aSnipbit ->
                                    if aSnipbit.id == mongoID then
                                        renderSnipbit
                                            { id = "view-snipbit-code-editor"
                                            , lang = Editor.aceLanguageLocation aSnipbit.language
                                            , theme = userTheme
                                            , value = aSnipbit.code
                                            , range = Nothing
                                            , readOnly = True
                                            }
                                    else
                                        getSnipbit mongoID

                        _ ->
                            doNothing

            GoTo route ->
                ( model
                , shared
                , Router.navigateTo route
                )

            LogOut ->
                ( model, shared, Api.getLogOut OnLogOutFailure OnLogOutSuccess )

            OnLogOutFailure apiError ->
                let
                    newModel =
                        { model
                            | logOutError = Just apiError
                        }
                in
                    ( newModel, shared, Cmd.none )

            OnLogOutSuccess basicResponse ->
                ( HomeInit.init
                , defaultShared
                , Router.navigateTo Route.WelcomeComponentRegister
                )

            ShowInfoFor maybeTidbitType ->
                ( { model | showInfoFor = maybeTidbitType }, shared, Cmd.none )

            SnipbitUpdateLanguageQuery newLanguageQuery ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | languageQuery = newLanguageQuery
                        }
                in
                    ( updateSnipbitCreateData newCreatingSnipbitData
                    , shared
                    , Cmd.none
                    )

            SnipbitUpdateACState acMsg ->
                let
                    ( newACState, maybeMsg ) =
                        AC.update
                            acUpdateConfig
                            acMsg
                            currentCreatingSnipbitData.languageListHowManyToShow
                            currentCreatingSnipbitData.languageQueryACState
                            (filterLanguagesByQuery
                                currentCreatingSnipbitData.languageQuery
                                shared.languages
                            )

                    newModel =
                        updateSnipbitCreateData
                            { currentCreatingSnipbitData
                                | languageQueryACState = newACState
                            }
                in
                    case maybeMsg of
                        Nothing ->
                            ( newModel, shared, Cmd.none )

                        Just updateMsg ->
                            update updateMsg newModel shared

            SnipbitUpdateACWrap toTop ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | languageQueryACState =
                                (if toTop then
                                    AC.resetToLastItem
                                 else
                                    AC.resetToFirstItem
                                )
                                    acUpdateConfig
                                    (filterLanguagesByQuery
                                        model.creatingSnipbitData.languageQuery
                                        shared.languages
                                    )
                                    currentCreatingSnipbitData.languageListHowManyToShow
                                    currentCreatingSnipbitData.languageQueryACState
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitSelectLanguage maybeEncodedLang ->
                let
                    language =
                        case maybeEncodedLang of
                            -- Erasing the selected language.
                            Nothing ->
                                Nothing

                            -- Selecting a language.
                            Just encodedLang ->
                                Util.quote
                                    >> Decode.decodeString Editor.languageCacheDecoder
                                    >> Result.toMaybe
                                <|
                                    encodedLang

                    -- If the user wants to select a new language, we help them
                    -- by focussing the input box.
                    newCmd =
                        if Util.isNothing language then
                            Task.attempt (\_ -> NoOp) (Dom.focus "language-query-input")
                        else
                            Cmd.none

                    newLanguageQuery =
                        case language of
                            Nothing ->
                                ""

                            Just aLanguage ->
                                toString aLanguage

                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | language = language
                            , languageQuery = newLanguageQuery
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, newCmd )

            SnipbitReset ->
                let
                    newModel =
                        updateSnipbitCreateData <| .creatingSnipbitData HomeInit.init
                in
                    ( newModel, shared, Router.navigateTo Route.HomeComponentCreateSnipbitName )

            SnipbitUpdateName newName ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | name = newName
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateDescription newDescription ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | description = newDescription
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            if
                                String.isEmpty newTag
                                    || List.member
                                        newTag
                                        currentCreatingSnipbitData.tags
                            then
                                currentCreatingSnipbitData.tags
                            else
                                currentCreatingSnipbitData.tags ++ [ newTag ]

                        newCreatingSnipbitData =
                            { currentCreatingSnipbitData
                                | tagInput = ""
                                , tags = newTags
                            }

                        newModel =
                            updateSnipbitCreateData newCreatingSnipbitData
                    in
                        ( newModel, shared, Cmd.none )
                else
                    let
                        newCreatingSnipbitData =
                            { currentCreatingSnipbitData
                                | tagInput = newTagInput
                            }

                        newModel =
                            updateSnipbitCreateData newCreatingSnipbitData
                    in
                        ( newModel, shared, Cmd.none )

            SnipbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\aTag -> aTag /= tagName)
                            currentCreatingSnipbitData.tags

                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | tags = newTags
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitAddTag tagName ->
                let
                    newTags =
                        if
                            String.isEmpty tagName
                                || List.member
                                    tagName
                                    currentCreatingSnipbitData.tags
                        then
                            currentCreatingSnipbitData.tags
                        else
                            currentCreatingSnipbitData.tags ++ [ tagName ]

                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | tags = newTags
                            , tagInput = ""
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitNewRangeSelected newRange ->
                case shared.route of
                    Route.HomeComponentCreateSnipbitCodeIntroduction ->
                        doNothing

                    Route.HomeComponentCreateSnipbitCodeConclusion ->
                        doNothing

                    Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                        let
                            frameIndex =
                                frameNumber - 1
                        in
                            case (Array.get frameIndex currentHighlightedComments) of
                                Nothing ->
                                    doNothing

                                Just currentFrameHighlightedComment ->
                                    let
                                        newFrame =
                                            { currentFrameHighlightedComment
                                                | range = Just newRange
                                            }

                                        newHighlightedComments =
                                            Array.set
                                                frameIndex
                                                newFrame
                                                currentHighlightedComments

                                        newCreatingSnipbitData =
                                            { currentCreatingSnipbitData
                                                | highlightedComments = newHighlightedComments
                                            }

                                        newModel =
                                            updateSnipbitCreateData
                                                newCreatingSnipbitData
                                    in
                                        ( newModel, shared, Cmd.none )

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

            SnipbitAddFrame ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | highlightedComments =
                                (Array.push
                                    { range = Nothing, comment = Nothing }
                                    currentHighlightedComments
                                )
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData

                    newMsg =
                        GoTo <|
                            Route.HomeComponentCreateSnipbitCodeFrame <|
                                Array.length
                                    newModel.creatingSnipbitData.highlightedComments
                in
                    update newMsg newModel shared

            SnipbitRemoveFrame ->
                let
                    newHighlightedComments =
                        Array.slice
                            0
                            (Array.length currentHighlightedComments - 1)
                            currentHighlightedComments

                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | highlightedComments =
                                newHighlightedComments
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData

                    result =
                        ( newModel, shared, Cmd.none )
                in
                    case shared.route of
                        Route.HomeComponentCreateSnipbitCodeIntroduction ->
                            result

                        Route.HomeComponentCreateSnipbitCodeConclusion ->
                            result

                        -- We need to go "down" a tab if the user was on the
                        -- last tab and they removed a tab.
                        Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                if frameIndex >= (Array.length newHighlightedComments) then
                                    update
                                        (GoTo <|
                                            Route.HomeComponentCreateSnipbitCodeFrame <|
                                                Array.length newHighlightedComments
                                        )
                                        newModel
                                        shared
                                else
                                    result

                        -- Should never happen.
                        _ ->
                            result

            SnipbitUpdateFrameComment index newComment ->
                case Array.get index currentHighlightedComments of
                    Nothing ->
                        doNothing

                    Just highlightComment ->
                        let
                            newHighlightComment =
                                { highlightComment
                                    | comment = Just newComment
                                }

                            newHighlightedComments =
                                Array.set
                                    index
                                    newHighlightComment
                                    currentHighlightedComments

                            newCreatingSnipbitData =
                                { currentCreatingSnipbitData
                                    | highlightedComments = newHighlightedComments
                                }

                            newModel =
                                updateSnipbitCreateData newCreatingSnipbitData
                        in
                            ( newModel, shared, Cmd.none )

            SnipbitUpdateIntroduction newIntro ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | introduction = newIntro
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitUpdateConclusion newConclusion ->
                let
                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | conclusion = newConclusion
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            -- On top of updating the code, we need to check that no highlights
            -- are now out of range. If highlights are now out of range we
            -- minimize them to the greatest size they can be whilst still being
            -- in range.
            SnipbitUpdateCode newCode ->
                let
                    rowsOfCode =
                        String.split "\n" newCode

                    maxRow =
                        List.length rowsOfCode - 1

                    lastRow =
                        Util.lastElem rowsOfCode

                    maxCol =
                        case lastRow of
                            Nothing ->
                                0

                            Just lastRowString ->
                                String.length lastRowString

                    getNewColAndRow : Int -> Int -> Int -> Int -> ( Int, Int )
                    getNewColAndRow currentRow currentCol lastRow lastCol =
                        if currentRow < lastRow then
                            ( currentRow, currentCol )
                        else if currentRow == maxRow then
                            ( currentRow, min currentCol lastCol )
                        else
                            ( lastRow, lastCol )

                    newHighlightedComments =
                        Array.map
                            (\comment ->
                                case comment.range of
                                    Nothing ->
                                        comment

                                    Just aRange ->
                                        let
                                            ( newStartRow, newStartCol ) =
                                                getNewColAndRow
                                                    aRange.startRow
                                                    aRange.startCol
                                                    maxRow
                                                    maxCol

                                            ( newEndRow, newEndCol ) =
                                                getNewColAndRow
                                                    aRange.endRow
                                                    aRange.endCol
                                                    maxRow
                                                    maxCol

                                            newRange =
                                                { startRow = newStartRow
                                                , startCol = newStartCol
                                                , endRow = newEndRow
                                                , endCol = newEndCol
                                                }
                                        in
                                            { comment
                                                | range = Just newRange
                                            }
                            )
                            currentHighlightedComments

                    newCreatingSnipbitData =
                        { currentCreatingSnipbitData
                            | code = newCode
                            , highlightedComments = newHighlightedComments
                        }

                    newModel =
                        updateSnipbitCreateData newCreatingSnipbitData
                in
                    ( newModel, shared, Cmd.none )

            SnipbitPublish snipbit ->
                ( model
                , shared
                , Api.postCreateSnipbit
                    snipbit
                    OnSnipbitPublishFailure
                    OnSnipbitPublishSuccess
                )

            OnSnipbitPublishSuccess createSnipbitResponse ->
                ( { model
                    | creatingSnipbitData = .creatingSnipbitData HomeInit.init
                  }
                , shared
                , Router.navigateTo <| Route.HomeComponentViewSnipbitIntroduction createSnipbitResponse.newID
                )

            OnSnipbitPublishFailure apiError ->
                -- TODO Handle Publish Failures.
                doNothing

            OnGetSnipbitFailure apiFailure ->
                -- TODO Handle get snipbit failure.
                doNothing

            OnGetSnipbitSuccess snipbit ->
                let
                    -- TODO get user theme.
                    userTheme =
                        ""
                in
                    ( { model
                        | viewingSnipbit = Just snipbit
                      }
                    , shared
                    , Ports.createCodeEditor
                        { id = "view-snipbit-code-editor"
                        , lang = Editor.aceLanguageLocation snipbit.language
                        , theme = userTheme
                        , value = snipbit.code
                        , range =
                            case shared.route of
                                Route.HomeComponentViewSnipbitFrame _ frameNumber ->
                                    (Array.get
                                        (frameNumber - 1)
                                        snipbit.highlightedComments
                                    )
                                        |> Maybe.map .range

                                _ ->
                                    Nothing
                        , readOnly = True
                        }
                    )


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query languages =
    List.filter
        (String.contains (String.toLower query) << Tuple.second)
        languages


{-| Config for language-list auto-complete (used in snipbit creation).
-}
acUpdateConfig : AC.UpdateConfig Msg ( Editor.Language, String )
acUpdateConfig =
    let
        downKeyCode =
            38

        upKeyCode =
            40

        enterKeyCode =
            13
    in
        AC.updateConfig
            { toId = (toString << Tuple.first)
            , onKeyDown =
                \keyCode maybeID ->
                    if keyCode == downKeyCode || keyCode == upKeyCode then
                        Nothing
                    else if keyCode == enterKeyCode then
                        if Util.isNothing maybeID then
                            Nothing
                        else
                            Just <| SnipbitSelectLanguage maybeID
                    else
                        Nothing
            , onTooLow = Just <| SnipbitUpdateACWrap False
            , onTooHigh = Just <| SnipbitUpdateACWrap True
            , onMouseClick =
                \id ->
                    Just <| SnipbitSelectLanguage <| Just id
            , onMouseLeave = \_ -> Nothing
            , onMouseEnter = \_ -> Nothing
            , separateSelections = False
            }
