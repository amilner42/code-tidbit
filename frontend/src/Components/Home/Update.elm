module Components.Home.Update exposing (update, filterLanguagesByQuery)

import Array
import Api
import Autocomplete as AC
import Components.Home.Init as HomeInit
import Components.Home.Messages exposing (Msg(..))
import Components.Home.Model exposing (Model)
import Components.Model exposing (Shared)
import DefaultModel exposing (defaultShared)
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Json.Decode as Decode
import Models.BasicTidbit as BasicTidbit
import Models.Route as Route
import Router
import Ports


{-| Home Component Update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        updateBasicTidbitCreateData : BasicTidbit.BasicTidbitCreateData -> Model
        updateBasicTidbitCreateData newCreatingBasicTidbitData =
            { model
                | creatingBasicTidbitData = newCreatingBasicTidbitData
            }

        currentCreatingBasicTidbitData : BasicTidbit.BasicTidbitCreateData
        currentCreatingBasicTidbitData =
            model.creatingBasicTidbitData

        currentHighlightedComments =
            currentCreatingBasicTidbitData.highlightedComments
    in
        case msg of
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
                , Router.navigateTo Route.WelcomeComponentLogin
                )

            BasicTidbitUpdateLanguageQuery newLanguageQuery ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | languageQuery = newLanguageQuery
                        }
                in
                    ( updateBasicTidbitCreateData newCreatingBasicTidbitData
                    , shared
                    , Cmd.none
                    )

            BasicTidbitUpdateACState acMsg ->
                let
                    downKeyCode =
                        38

                    upKeyCode =
                        40

                    enterKeyCode =
                        13

                    acUpdateConfig : AC.UpdateConfig Msg ( Editor.Language, String )
                    acUpdateConfig =
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
                                            Just <| BasicTidbitSelectLanguage maybeID
                                    else
                                        Nothing
                            , onTooLow = Nothing
                            , onTooHigh = Nothing
                            , onMouseClick =
                                \id ->
                                    Just <| BasicTidbitSelectLanguage <| Just id
                            , onMouseLeave = \_ -> Nothing
                            , onMouseEnter = \_ -> Nothing
                            , separateSelections = False
                            }

                    ( newACState, maybeMsg ) =
                        AC.update
                            acUpdateConfig
                            acMsg
                            8
                            currentCreatingBasicTidbitData.languageQueryACState
                            (filterLanguagesByQuery
                                currentCreatingBasicTidbitData.languageQuery
                                shared.languages
                            )

                    newModel =
                        updateBasicTidbitCreateData
                            { currentCreatingBasicTidbitData
                                | languageQueryACState = newACState
                            }
                in
                    case maybeMsg of
                        Nothing ->
                            ( newModel, shared, Cmd.none )

                        Just updateMsg ->
                            update updateMsg newModel shared

            BasicTidbitSelectLanguage maybeEncodedLang ->
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

                    newLanguageQuery =
                        case language of
                            Nothing ->
                                ""

                            Just aLanguage ->
                                toString aLanguage

                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | language = language
                            , languageQuery = newLanguageQuery
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            ResetCreateBasicTidbit ->
                let
                    newModel =
                        updateBasicTidbitCreateData <| .creatingBasicTidbitData HomeInit.init
                in
                    ( newModel, shared, Router.navigateTo Route.HomeComponentCreateBasicName )

            BasicTidbitUpdateName newName ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | name = newName
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitUpdateDescription newDescription ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | description = newDescription
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            if
                                String.isEmpty newTag
                                    || List.member
                                        newTag
                                        currentCreatingBasicTidbitData.tags
                            then
                                currentCreatingBasicTidbitData.tags
                            else
                                currentCreatingBasicTidbitData.tags ++ [ newTag ]

                        newCreatingBasicTidbitData =
                            { currentCreatingBasicTidbitData
                                | tagInput = ""
                                , tags = newTags
                            }

                        newModel =
                            updateBasicTidbitCreateData newCreatingBasicTidbitData
                    in
                        ( newModel, shared, Cmd.none )
                else
                    let
                        newCreatingBasicTidbitData =
                            { currentCreatingBasicTidbitData
                                | tagInput = newTagInput
                            }

                        newModel =
                            updateBasicTidbitCreateData newCreatingBasicTidbitData
                    in
                        ( newModel, shared, Cmd.none )

            BasicTidbitRemoveTag tagName ->
                let
                    newTags =
                        List.filter
                            (\aTag -> aTag /= tagName)
                            currentCreatingBasicTidbitData.tags

                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | tags = newTags
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitAddTag tagName ->
                let
                    newTags =
                        if
                            String.isEmpty tagName
                                || List.member
                                    tagName
                                    currentCreatingBasicTidbitData.tags
                        then
                            currentCreatingBasicTidbitData.tags
                        else
                            currentCreatingBasicTidbitData.tags ++ [ tagName ]

                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | tags = newTags
                            , tagInput = ""
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitNewRangeSelected newRange ->
                case shared.route of
                    Route.HomeComponentCreateBasicTidbitIntroduction ->
                        doNothing

                    Route.HomeComponentCreateBasicTidbitConclusion ->
                        doNothing

                    Route.HomeComponentCreateBasicTidbitFrame frameNumber ->
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

                                        newCreatingBasicTidbitData =
                                            { currentCreatingBasicTidbitData
                                                | highlightedComments = newHighlightedComments
                                            }

                                        newModel =
                                            updateBasicTidbitCreateData
                                                newCreatingBasicTidbitData
                                    in
                                        ( newModel, shared, Cmd.none )

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

            BasicTidbitAddFrame ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | highlightedComments =
                                (Array.push
                                    { range = Nothing, comment = Nothing }
                                    currentHighlightedComments
                                )
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData

                    newMsg =
                        GoTo <|
                            Route.HomeComponentCreateBasicTidbitFrame <|
                                Array.length
                                    newModel.creatingBasicTidbitData.highlightedComments
                in
                    update newMsg newModel shared

            BasicTidbitRemoveFrame ->
                let
                    newHighlightedComments =
                        Array.slice
                            0
                            (Array.length currentHighlightedComments - 1)
                            currentHighlightedComments

                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | highlightedComments =
                                newHighlightedComments
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData

                    result =
                        ( newModel, shared, Cmd.none )
                in
                    case shared.route of
                        Route.HomeComponentCreateBasicTidbitIntroduction ->
                            result

                        Route.HomeComponentCreateBasicTidbitConclusion ->
                            result

                        -- We need to go "down" a tab if the user was on the
                        -- last tab and they removed a tab.
                        Route.HomeComponentCreateBasicTidbitFrame frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                if frameIndex >= (Array.length newHighlightedComments) then
                                    update
                                        (GoTo <|
                                            Route.HomeComponentCreateBasicTidbitFrame <|
                                                Array.length newHighlightedComments
                                        )
                                        newModel
                                        shared
                                else
                                    result

                        -- Should never happen.
                        _ ->
                            result

            BasicTidbitUpdateFrameComment index newComment ->
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

                            newCreatingBasicTidbitData =
                                { currentCreatingBasicTidbitData
                                    | highlightedComments = newHighlightedComments
                                }

                            newModel =
                                updateBasicTidbitCreateData newCreatingBasicTidbitData
                        in
                            ( newModel, shared, Cmd.none )

            BasicTidbitUpdateIntroduction newIntro ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | introduction = newIntro
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitUpdateConclusion newConclusion ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | conclusion = newConclusion
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            -- On top of updating the code, we need to check that no highlights
            -- are now out of range. If highlights are now out of range we
            -- minimize them to the greatest size they can be whilst still being
            -- in range.
            BasicTidbitUpdateCode newCode ->
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

                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | code = newCode
                            , highlightedComments = newHighlightedComments
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitPublish basicTidbit ->
                ( model
                , shared
                , Api.postBasicCodeTidbit
                    basicTidbit
                    OnBasicTidbitPublishFailure
                    OnBasicTidbitPublishSuccess
                )

            OnBasicTidbitPublishSuccess basicResponse ->
                update ResetCreateBasicTidbit model shared

            OnBasicTidbitPublishFailure apiError ->
                -- TODO Handle Publish Failures.
                doNothing


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query languages =
    List.filter
        (String.contains (String.toLower query) << Tuple.second)
        languages
