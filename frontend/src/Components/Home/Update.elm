module Components.Home.Update exposing (update, filterLanguagesByQuery)

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
        updateBasicTidbitCreateData : BasicTidbit.BasicTidbitCreateData -> Model
        updateBasicTidbitCreateData newCreatingBasicTidbitData =
            { model
                | creatingBasicTidbitData = newCreatingBasicTidbitData
            }

        currentCreatingBasicTidbitData : BasicTidbit.BasicTidbitCreateData
        currentCreatingBasicTidbitData =
            model.creatingBasicTidbitData
    in
        case msg of
            GoToBrowseView ->
                ( model
                , shared
                , Router.navigateTo Route.HomeComponentBrowse
                )

            GoToCreateView ->
                ( model
                , shared
                , Router.navigateTo Route.HomeComponentCreate
                )

            GoToProfileView ->
                ( model
                , shared
                , Router.navigateTo Route.HomeComponentProfile
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

            CreateEditor idName ->
                ( model
                , shared
                , Ports.createCodeEditor idName
                )

            SelectTidbitTypeForCreate tidbitType ->
                let
                    newModel =
                        { model | creatingTidbitType = tidbitType }
                in
                    ( newModel, shared, Cmd.none )

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

            BasicTidbitSelectTab newStageSelected ->
                let
                    newCreatingBasicTidbitData =
                        { currentCreatingBasicTidbitData
                            | createStage = newStageSelected
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


{-| Filters the languages based on `query`.
-}
filterLanguagesByQuery : String -> List ( Editor.Language, String ) -> List ( Editor.Language, String )
filterLanguagesByQuery query languages =
    List.filter
        (String.contains (String.toLower query) << Tuple.second)
        languages
