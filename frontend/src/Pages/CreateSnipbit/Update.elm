module Pages.CreateSnipbit.Update exposing (..)

import Api exposing (api)
import Array
import Autocomplete as AC
import DefaultServices.ArrayExtra as ArrayExtra
import DefaultServices.CommonSubPageUtil exposing (CommonSubPageUtil(..), commonSubPageUtil)
import DefaultServices.TextFields as TextFields
import DefaultServices.Util as Util exposing (maybeMapWithDefault, togglePreviewMarkdown)
import Elements.Simple.Editor as Editor
import JSON.Language
import Json.Decode as Decode
import Models.Range as Range
import Models.RequestTracker as RT
import Models.Route as Route
import Models.User as User
import Pages.CreateSnipbit.Init exposing (..)
import Pages.CreateSnipbit.Messages exposing (..)
import Pages.CreateSnipbit.Model exposing (..)
import Pages.Messages as BaseMessage
import Pages.Model exposing (Shared)
import Ports


{-| `CreateSnipbit` update.
-}
update : CommonSubPageUtil Model Shared Msg BaseMessage.Msg -> Msg -> Model -> Shared -> ( Model, Shared, Cmd BaseMessage.Msg )
update (Common common) msg model shared =
    let
        currentHighlightedComments =
            model.highlightedComments

        focusOn =
            Util.domFocus (always BaseMessage.NoOp)
    in
    case msg of
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
                            , useMarker = False
                            , readOnly = model.codeLocked
                            , selectAllowed = True
                            }
                        , Ports.smoothScrollToBottom
                        ]
            in
            case route of
                Route.CreateSnipbitNamePage ->
                    ( resetConfirmState model, shared, focusOn "name-input" )

                Route.CreateSnipbitDescriptionPage ->
                    ( resetConfirmState model, shared, focusOn "description-input" )

                Route.CreateSnipbitLanguagePage ->
                    ( resetConfirmState model, shared, focusOn "language-query-input" )

                Route.CreateSnipbitTagsPage ->
                    ( resetConfirmState model, shared, focusOn "tags-input" )

                Route.CreateSnipbitCodeFramePage frameNumber ->
                    let
                        -- 0 based indexing.
                        frameIndex =
                            frameNumber - 1

                        frameIndexTooHigh =
                            frameIndex >= Array.length model.highlightedComments

                        frameIndexTooLow =
                            frameIndex < 0
                    in
                    if frameIndexTooLow then
                        ( resetConfirmState model, shared, Route.modifyTo <| Route.CreateSnipbitTagsPage )
                    else if frameIndexTooHigh then
                        ( resetConfirmState model
                        , shared
                        , Array.length model.highlightedComments
                            |> Route.CreateSnipbitCodeFramePage
                            |> Route.modifyTo
                        )
                    else
                        let
                            -- Either the existing range, the range from
                            -- the previous frame collapsed, or Nothing.
                            newHCRange =
                                Array.get frameIndex model.highlightedComments
                                    |> Maybe.andThen .range
                                    |> (\maybeRange ->
                                            case maybeRange of
                                                Nothing ->
                                                    previousFrameRange model shared.route
                                                        |> Maybe.map Range.collapseRange

                                                Just range ->
                                                    Just range
                                       )
                        in
                        ( { model
                            | highlightedComments =
                                ArrayExtra.update
                                    frameIndex
                                    (\currentHC -> { currentHC | range = newHCRange })
                                    model.highlightedComments
                          }
                            |> resetConfirmState
                        , shared
                        , Cmd.batch
                            [ createCreateSnipbitEditor newHCRange
                            , focusOn "frame-input"
                            ]
                        )

                _ ->
                    common.doNothing

        OnRangeSelected newRange ->
            case shared.route of
                Route.CreateSnipbitCodeFramePage frameNumber ->
                    let
                        frameIndex =
                            frameNumber - 1
                    in
                    case Array.get frameIndex currentHighlightedComments of
                        Nothing ->
                            common.doNothing

                        Just currentFrameHighlightedComment ->
                            let
                                newFrame =
                                    { currentFrameHighlightedComment | range = Just newRange }

                                newHighlightedComments =
                                    Array.set frameIndex newFrame currentHighlightedComments
                            in
                            common.justSetModel { model | highlightedComments = newHighlightedComments }

                -- Should never happen (highlighting when not on the editor pages).
                _ ->
                    common.doNothing

        OnUpdateACState acMsg ->
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
                    { model | languageQueryACState = newACState }
            in
            case maybeMsg of
                Nothing ->
                    common.justSetModel newModel

                Just updateMsg ->
                    update (commonSubPageUtil common.subMsg newModel shared) updateMsg newModel shared

        OnUpdateACWrap toTop ->
            common.justSetModel
                { model
                    | languageQueryACState =
                        (if toTop then
                            AC.resetToLastItem
                         else
                            AC.resetToFirstItem
                        )
                            acUpdateConfig
                            (filterLanguagesByQuery model.languageQuery shared.languages)
                            model.languageListHowManyToShow
                            model.languageQueryACState
                }

        -- On top of updating the code, we need to check that no highlights are now out of range. If highlights are
        -- now out of range we minimize them to the greatest size they can be whilst still being in range.
        OnUpdateCode { newCode, action, deltaRange } ->
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
            common.justSetModel
                { model
                    | code = newCode
                    , highlightedComments = newHighlightedComments
                }

        GoToCodeTab ->
            ( { model | previewMarkdown = False }
            , shared
            , Route.navigateTo <| Route.CreateSnipbitCodeFramePage 1
            )

        Reset ->
            if model.confirmedReset then
                ( init
                , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-snipbit-name" }
                , Route.navigateTo Route.CreateSnipbitNamePage
                )
            else
                common.justSetModel { model | confirmedReset = True }

        AddFrame ->
            let
                newModel =
                    { model
                        | highlightedComments =
                            currentHighlightedComments
                                |> Array.push { range = Nothing, comment = Nothing }
                        , confirmedRemoveFrame = False
                    }

                newCmd =
                    Route.navigateTo <| Route.CreateSnipbitCodeFramePage <| Array.length newModel.highlightedComments
            in
            ( newModel, shared, newCmd )

        RemoveFrame ->
            if Array.length currentHighlightedComments == 1 then
                common.doNothing
            else if not model.confirmedRemoveFrame then
                common.justSetModel { model | confirmedRemoveFrame = True }
            else
                let
                    newHighlightedComments =
                        Array.slice 0 (Array.length currentHighlightedComments - 1) currentHighlightedComments

                    newModel =
                        { model | highlightedComments = newHighlightedComments, confirmedRemoveFrame = False }
                in
                case shared.route of
                    Route.CreateSnipbitCodeFramePage frameNumber ->
                        let
                            frameIndex =
                                frameNumber - 1
                        in
                        ( newModel
                        , shared
                        , -- We need to go "down" a tab if the user was on the last tab and they removed a tab.
                          if frameIndex >= Array.length newHighlightedComments then
                            Route.navigateTo <| Route.CreateSnipbitCodeFramePage <| Array.length newHighlightedComments
                          else
                            Cmd.none
                        )

                    -- Should never happen.
                    _ ->
                        common.justSetModel newModel

        TogglePreviewMarkdown ->
            common.justSetModel <| Util.togglePreviewMarkdown model

        JumpToLineFromPreviousFrame ->
            case shared.route of
                Route.CreateSnipbitCodeFramePage frameNumber ->
                    ( { model
                        | highlightedComments =
                            ArrayExtra.update
                                (frameNumber - 1)
                                (\hc -> { hc | range = Nothing })
                                model.highlightedComments
                      }
                    , shared
                    , Route.modifyTo shared.route
                    )

                _ ->
                    common.doNothing

        OnUpdateLanguageQuery newLanguageQuery ->
            common.justSetModel
                { model
                    | languageQuery = newLanguageQuery
                    , languageQueryACState = AC.reset acUpdateConfig model.languageQueryACState
                }

        SelectLanguage maybeEncodedLang ->
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

                -- If the user wants to select a new language, we help them by focussing the input box.
                newCmd =
                    if Util.isNothing language then
                        focusOn "language-query-input"
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
            ( newModel
            , { shared
                | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-snipbit-language"
              }
            , newCmd
            )

        OnUpdateName newName ->
            common.justSetModel { model | name = newName }

        OnUpdateDescription newDescription ->
            common.justSetModel { model | description = newDescription }

        OnUpdateTagInput newTagInput ->
            common.justSetModel { model | tagInput = newTagInput }

        RemoveTag tagName ->
            common.justSetModel { model | tags = List.filter (\aTag -> aTag /= tagName) model.tags }

        AddTag tagName ->
            ( { model
                | tags = Util.addUniqueNonEmptyString tagName model.tags
                , tagInput = ""
              }
            , { shared | textFieldKeyTracker = TextFields.changeKey shared.textFieldKeyTracker "create-snipbit-tags" }
            , focusOn "tags-input"
            )

        OnUpdateFrameComment index newComment ->
            case Array.get index currentHighlightedComments of
                Nothing ->
                    common.doNothing

                Just highlightComment ->
                    let
                        newHighlightComment =
                            { highlightComment | comment = Just newComment }

                        newHighlightedComments =
                            Array.set index newHighlightComment currentHighlightedComments
                    in
                    common.justSetModel { model | highlightedComments = newHighlightedComments }

        Publish snipbit ->
            let
                publishSnipbitAction =
                    common.justProduceCmd <|
                        api.post.createSnipbit
                            snipbit
                            (common.subMsg << OnPublishFailure)
                            (common.subMsg << OnPublishSuccess)
            in
            common.makeSingletonRequest RT.PublishSnipbit publishSnipbitAction

        OnPublishSuccess { targetID } ->
            ( init
            , { shared | userTidbits = Nothing }
            , Route.navigateTo <| Route.ViewSnipbitFramePage Nothing targetID 1
            )
                |> common.andFinishRequest RT.PublishSnipbit

        OnPublishFailure apiError ->
            common.justSetModalError apiError
                |> common.andFinishRequest RT.PublishSnipbit

        ToggleLockCode ->
            ( { model | codeLocked = not model.codeLocked }, shared, Route.modifyTo <| shared.route )


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
        { toId = toString << Tuple.first
        , onKeyDown =
            \keyCode maybeID ->
                if keyCode == downKeyCode || keyCode == upKeyCode then
                    Nothing
                else if keyCode == enterKeyCode then
                    if Util.isNothing maybeID then
                        Nothing
                    else
                        Just <| SelectLanguage maybeID
                else
                    Nothing
        , onTooLow = Just <| OnUpdateACWrap False
        , onTooHigh = Just <| OnUpdateACWrap True
        , onMouseClick =
            \id ->
                Just <| SelectLanguage <| Just id
        , onMouseLeave = \_ -> Nothing
        , onMouseEnter = \_ -> Nothing
        , separateSelections = False
        }
