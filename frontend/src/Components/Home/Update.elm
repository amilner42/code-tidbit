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
                    ( newModel, shared, Cmd.none )

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

            BasicTidbitGoToCommentTab commentTab ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | currentCommentTab = commentTab
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )

            BasicTidbitNewRangeSelected newRange ->
                case currentCreatingBasicTidbitData.currentCommentTab of
                    BasicTidbit.Introduction ->
                        doNothing

                    BasicTidbit.Conclusion ->
                        doNothing

                    BasicTidbit.Frame frameNumber ->
                        case (Array.get frameNumber currentHighlightedComments) of
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
                                            frameNumber
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
                        BasicTidbitGoToCommentTab <|
                            BasicTidbit.Frame <|
                                Array.length
                                    newModel.creatingBasicTidbitData.highlightedComments
                                    - 1
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
                    case currentCreatingBasicTidbitData.currentCommentTab of
                        BasicTidbit.Introduction ->
                            result

                        BasicTidbit.Conclusion ->
                            result

                        -- We need to go "down" a tab if the user was on the
                        -- last tab and they removed a tab.
                        BasicTidbit.Frame frameIndex ->
                            if frameIndex >= (Array.length newHighlightedComments) then
                                update
                                    (BasicTidbitGoToCommentTab <|
                                        BasicTidbit.Frame <|
                                            Array.length newHighlightedComments
                                                - 1
                                    )
                                    newModel
                                    shared
                            else
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

            BasicTidbitUpdateCode newCode ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | code = newCode
                        }

                    newModel =
                        updateBasicTidbitCreateData newCreatingBasicTidbitData
                in
                    ( newModel, shared, Cmd.none )


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query languages =
    List.filter
        (String.contains (String.toLower query) << Tuple.second)
        languages
