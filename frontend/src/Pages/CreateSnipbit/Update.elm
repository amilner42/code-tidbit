module Pages.CreateSnipbit.Update exposing (..)

import Api
import Array
import Autocomplete as AC
import DefaultServices.ArrayExtra as ArrayExtra
import DefaultServices.Util as Util exposing (togglePreviewMarkdown, maybeMapWithDefault)
import Elements.Editor as Editor
import JSON.Language
import Json.Decode as Decode
import Models.Range as Range
import Models.Route as Route
import Models.User as User
import Pages.CreateSnipbit.Init exposing (..)
import Pages.CreateSnipbit.Messages exposing (..)
import Pages.CreateSnipbit.Model exposing (..)
import Pages.Model exposing (Shared)
import Ports


{-| `CreateSnipbit` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )

        justSetModel newModel =
            ( newModel, shared, Cmd.none )

        currentHighlightedComments =
            model.highlightedComments
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                let
                    createCreateSnipbitEditor aceRange =
                        let
                            aceLang =
                                maybeMapWithDefault
                                    Editor.aceLanguageLocation
                                    ""
                                    model.language
                        in
                            Cmd.batch
                                [ Ports.createCodeEditor
                                    { id = "create-snipbit-code-editor"
                                    , fileID = ""
                                    , lang = aceLang
                                    , theme = User.getTheme shared.user
                                    , value = model.code
                                    , range = aceRange
                                    , readOnly = False
                                    , selectAllowed = True
                                    }
                                , Ports.smoothScrollToBottom
                                ]

                    focusOn theID =
                        justProduceCmd <|
                            Util.domFocus (\_ -> NoOp) theID
                in
                    case route of
                        Route.CreateSnipbitNamePage ->
                            focusOn "name-input"

                        Route.CreateSnipbitDescriptionPage ->
                            focusOn "description-input"

                        Route.CreateSnipbitLanguagePage ->
                            focusOn "language-query-input"

                        Route.CreateSnipbitTagsPage ->
                            focusOn "tags-input"

                        Route.CreateSnipbitCodeIntroductionPage ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateSnipbitEditor Nothing
                                    , Util.domFocus (\_ -> NoOp) "introduction-input"
                                    ]

                        Route.CreateSnipbitCodeFramePage frameNumber ->
                            let
                                -- 0 based indexing.
                                frameIndex =
                                    frameNumber - 1

                                frameIndexTooHigh =
                                    frameIndex >= (Array.length model.highlightedComments)

                                frameIndexTooLow =
                                    frameIndex < 0
                            in
                                if frameIndexTooLow then
                                    justProduceCmd <|
                                        Route.modifyTo
                                            Route.CreateSnipbitCodeIntroductionPage
                                else if frameIndexTooHigh then
                                    justProduceCmd <|
                                        Route.modifyTo
                                            Route.CreateSnipbitCodeConclusionPage
                                else
                                    let
                                        -- Either the existing range, the range from
                                        -- the previous frame collapsed, or Nothing.
                                        newHCRange =
                                            ((Array.get
                                                frameIndex
                                                model.highlightedComments
                                             )
                                                |> Maybe.andThen .range
                                                |> (\maybeRange ->
                                                        case maybeRange of
                                                            Nothing ->
                                                                previousFrameRange model shared.route
                                                                    |> Maybe.map Range.collapseRange

                                                            Just range ->
                                                                Just range
                                                   )
                                            )
                                    in
                                        ( { model
                                            | highlightedComments =
                                                ArrayExtra.update
                                                    frameIndex
                                                    (\currentHC ->
                                                        { currentHC
                                                            | range = newHCRange
                                                        }
                                                    )
                                                    model.highlightedComments
                                          }
                                        , shared
                                        , Cmd.batch
                                            [ createCreateSnipbitEditor newHCRange
                                            , Util.domFocus (\_ -> NoOp) "frame-input"
                                            ]
                                        )

                        Route.CreateSnipbitCodeConclusionPage ->
                            justProduceCmd <|
                                Cmd.batch
                                    [ createCreateSnipbitEditor Nothing
                                    , Util.domFocus (\_ -> NoOp) "conclusion-input"
                                    ]

                        _ ->
                            doNothing

            SnipbitGoToCodeTab ->
                ( { model
                    | previewMarkdown = False
                  }
                , shared
                , Route.navigateTo Route.CreateSnipbitCodeIntroductionPage
                )

            SnipbitUpdateLanguageQuery newLanguageQuery ->
                justSetModel <|
                    { model
                        | languageQuery = newLanguageQuery
                    }

            SnipbitUpdateACState acMsg ->
                let
                    ( newACState, maybeMsg ) =
                        AC.update
                            acUpdateConfig
                            acMsg
                            model.languageListHowManyToShow
                            model.languageQueryACState
                            (filterLanguagesByQuery
                                model.languageQuery
                                shared.languages
                            )

                    newModel =
                        { model
                            | languageQueryACState = newACState
                        }
                in
                    case maybeMsg of
                        Nothing ->
                            justSetModel <| newModel

                        Just updateMsg ->
                            update updateMsg newModel shared

            SnipbitUpdateACWrap toTop ->
                justSetModel
                    { model
                        | languageQueryACState =
                            (if toTop then
                                AC.resetToLastItem
                             else
                                AC.resetToFirstItem
                            )
                                acUpdateConfig
                                (filterLanguagesByQuery
                                    model.languageQuery
                                    shared.languages
                                )
                                model.languageListHowManyToShow
                                model.languageQueryACState
                    }

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
                                    >> Decode.decodeString JSON.Language.decoder
                                    >> Result.toMaybe
                                <|
                                    encodedLang

                    -- If the user wants to select a new language, we help them
                    -- by focussing the input box.
                    newCmd =
                        if Util.isNothing language then
                            Util.domFocus (always NoOp) "language-query-input"
                        else
                            Cmd.none

                    newLanguageQuery =
                        case language of
                            Nothing ->
                                ""

                            Just aLanguage ->
                                Editor.getHumanReadableName aLanguage

                    newModel =
                        { model
                            | language = language
                            , languageQuery = newLanguageQuery
                        }
                in
                    ( newModel, shared, newCmd )

            SnipbitReset ->
                ( init, shared, Route.navigateTo Route.CreateSnipbitNamePage )

            SnipbitUpdateName newName ->
                justSetModel
                    { model
                        | name = newName
                    }

            SnipbitUpdateDescription newDescription ->
                justSetModel
                    { model
                        | description = newDescription
                    }

            SnipbitUpdateTagInput newTagInput ->
                if String.endsWith " " newTagInput then
                    let
                        newTag =
                            String.dropRight 1 newTagInput

                        newTags =
                            Util.addUniqueNonEmptyString
                                newTag
                                model.tags
                    in
                        justSetModel <|
                            { model
                                | tagInput = ""
                                , tags = newTags
                            }
                else
                    justSetModel <|
                        { model
                            | tagInput = newTagInput
                        }

            SnipbitRemoveTag tagName ->
                justSetModel <|
                    { model
                        | tags =
                            List.filter
                                (\aTag -> aTag /= tagName)
                                model.tags
                    }

            SnipbitAddTag tagName ->
                justSetModel <|
                    { model
                        | tags =
                            Util.addUniqueNonEmptyString
                                tagName
                                model.tags
                        , tagInput = ""
                    }

            SnipbitNewRangeSelected newRange ->
                case shared.route of
                    Route.CreateSnipbitCodeIntroductionPage ->
                        doNothing

                    Route.CreateSnipbitCodeConclusionPage ->
                        doNothing

                    Route.CreateSnipbitCodeFramePage frameNumber ->
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
                                    in
                                        justSetModel <|
                                            { model
                                                | highlightedComments = newHighlightedComments
                                            }

                    -- Should never really happen (highlighting when not on
                    -- the editor pages).
                    _ ->
                        doNothing

            SnipbitTogglePreviewMarkdown ->
                justSetModel <|
                    Util.togglePreviewMarkdown model

            SnipbitAddFrame ->
                let
                    newModel =
                        { model
                            | highlightedComments =
                                (Array.push
                                    { range = Nothing, comment = Nothing }
                                    currentHighlightedComments
                                )
                        }

                    newMsg =
                        GoTo <|
                            Route.CreateSnipbitCodeFramePage <|
                                Array.length
                                    newModel.highlightedComments
                in
                    update newMsg newModel shared

            SnipbitRemoveFrame ->
                let
                    newHighlightedComments =
                        Array.slice
                            0
                            (Array.length currentHighlightedComments - 1)
                            currentHighlightedComments

                    newModel =
                        { model
                            | highlightedComments =
                                newHighlightedComments
                        }
                in
                    case shared.route of
                        Route.CreateSnipbitCodeIntroductionPage ->
                            justSetModel newModel

                        Route.CreateSnipbitCodeConclusionPage ->
                            justSetModel newModel

                        -- We need to go "down" a tab if the user was on the
                        -- last tab and they removed a tab.
                        Route.CreateSnipbitCodeFramePage frameNumber ->
                            let
                                frameIndex =
                                    frameNumber - 1
                            in
                                if frameIndex >= (Array.length newHighlightedComments) then
                                    update
                                        (GoTo <|
                                            Route.CreateSnipbitCodeFramePage <|
                                                Array.length newHighlightedComments
                                        )
                                        newModel
                                        shared
                                else
                                    justSetModel newModel

                        -- Should never happen.
                        _ ->
                            justSetModel newModel

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
                        in
                            justSetModel
                                { model
                                    | highlightedComments = newHighlightedComments
                                }

            SnipbitUpdateIntroduction newIntro ->
                justSetModel
                    { model
                        | introduction = newIntro
                    }

            SnipbitUpdateConclusion newConclusion ->
                justSetModel
                    { model
                        | conclusion = newConclusion
                    }

            -- On top of updating the code, we need to check that no highlights
            -- are now out of range. If highlights are now out of range we
            -- minimize them to the greatest size they can be whilst still being
            -- in range.
            SnipbitUpdateCode { newCode, action, deltaRange } ->
                let
                    currentCode =
                        model.code

                    newHighlightedComments =
                        Array.map
                            (\comment ->
                                case comment.range of
                                    Nothing ->
                                        comment

                                    Just aRange ->
                                        { comment
                                            | range =
                                                Just <|
                                                    Range.getNewRangeAfterDelta
                                                        currentCode
                                                        newCode
                                                        action
                                                        deltaRange
                                                        aRange
                                        }
                            )
                            currentHighlightedComments
                in
                    justSetModel
                        { model
                            | code = newCode
                            , highlightedComments = newHighlightedComments
                        }

            SnipbitPublish snipbit ->
                justProduceCmd <|
                    Api.postCreateSnipbit
                        snipbit
                        OnSnipbitPublishFailure
                        OnSnipbitPublishSuccess

            SnipbitJumpToLineFromPreviousFrame ->
                case shared.route of
                    Route.CreateSnipbitCodeFramePage frameNumber ->
                        ( { model
                            | highlightedComments =
                                ArrayExtra.update
                                    (frameNumber - 1)
                                    (\hc ->
                                        { hc
                                            | range = Nothing
                                        }
                                    )
                                    model.highlightedComments
                          }
                        , shared
                        , Route.modifyTo shared.route
                        )

                    _ ->
                        doNothing

            OnSnipbitPublishSuccess { targetID } ->
                ( init
                , { shared
                    | userTidbits = Nothing
                  }
                , Route.navigateTo <|
                    Route.ViewSnipbitIntroductionPage Nothing targetID
                )

            OnSnipbitPublishFailure apiError ->
                -- TODO Handle Publish Failures.
                doNothing


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
