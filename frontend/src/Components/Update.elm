module Components.Update exposing (update, updateCacheIf)

import Array
import Api
import Components.Home.Update as HomeUpdate
import Components.Home.Messages as HomeMessages
import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model, updateKeysDown, updateKeysDownWithKeys, kkUpdateWrapper)
import Components.Welcome.Update as WelcomeUpdate
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util
import Elements.Editor as Editor
import Keyboard.Extra as KK
import Models.Route as Route
import Navigation
import Ports
import Task


{-| Base Component Update.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updateCacheIf msg model True


{-| Sometimes we don't want to save to the cache, for example when the website
originally loads if we save to cache we end up loading what we saved (the
default model) instead of what was in their before.
-}
updateCacheIf : Msg -> Model -> Bool -> ( Model, Cmd Msg )
updateCacheIf msg model shouldCache =
    let
        shared =
            model.shared

        currentHomeComponent =
            model.homeComponent

        doNothing =
            ( model, Cmd.none )

        ( newModel, newCmd ) =
            case msg of
                NoOp ->
                    doNothing

                OnLocationChange location ->
                    let
                        newRoute =
                            Route.parseLocation location
                    in
                        handleLocationChange newRoute model

                LoadModelFromLocalStorage ->
                    ( model, LocalStorage.loadModel () )

                OnLoadModelFromLocalStorageSuccess newModel ->
                    ( newModel, Route.navigateTo shared.route )

                OnLoadModelFromLocalStorageFailure err ->
                    ( model, getUser () )

                GetUser ->
                    ( model, getUser () )

                OnGetUserSuccess user ->
                    let
                        newModel =
                            { model
                                | shared = { shared | user = Just user }
                            }
                    in
                        ( newModel, Route.navigateTo shared.route )

                OnGetUserFailure newApiError ->
                    let
                        newModel =
                            { model
                                | shared =
                                    { shared
                                        | route = Route.WelcomeComponentRegister
                                    }
                            }
                    in
                        ( newModel, Route.navigateTo newModel.shared.route )

                HomeMessage subMsg ->
                    let
                        ( newHomeModel, newShared, newSubMsg ) =
                            HomeUpdate.update
                                subMsg
                                model.homeComponent
                                model.shared

                        newModel =
                            { model
                                | homeComponent = newHomeModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map HomeMessage newSubMsg )

                WelcomeMessage subMsg ->
                    let
                        ( newWelcomeModel, newShared, newSubMsg ) =
                            WelcomeUpdate.update
                                subMsg
                                model.welcomeComponent
                                model.shared

                        newModel =
                            { model
                                | welcomeComponent = newWelcomeModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map WelcomeMessage newSubMsg )

                CodeEditorUpdate { id, value } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.SnipbitUpdateCode value
                                )
                                model
                                shouldCache
                            )

                        "create-bigbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.BigbitUpdateCode value
                                )
                                model
                                shouldCache
                            )

                        _ ->
                            doNothing

                CodeEditorSelectionUpdate { id, range } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.SnipbitNewRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "create-bigbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.BigbitNewRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "view-snipbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.ViewSnipbitRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "view-bigbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.ViewBigbitRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        _ ->
                            doNothing

                KeyboardExtraMessage msg ->
                    let
                        newKeysDown =
                            kkUpdateWrapper msg model.shared.keysDown

                        modelWithNewKeys =
                            updateKeysDown newKeysDown model
                    in
                        -- Key held, but no new key clicked. Get rid of this if
                        -- we need hotkeys with key-holds.
                        if model.shared.keysDown == newKeysDown then
                            doNothing
                        else
                            case msg of
                                KK.Down keyCode ->
                                    handleKeyPress modelWithNewKeys

                                KK.Up keyCode ->
                                    handleKeyRelease (KK.fromCode keyCode) modelWithNewKeys
    in
        case shouldCache of
            True ->
                ( newModel
                , Cmd.batch
                    [ newCmd
                    , LocalStorage.saveModel newModel
                    ]
                )

            False ->
                ( newModel, newCmd )


{-| Logic for handling new key-press, all keys currently pressed exist in
`shared.keysDown`.

NOTE: This doesn't require that a specific element be focussed, put logic for
route hotkeys here, if you want a hotkey only if a certain element is focussed,
stick to putting that on the element itself.
-}
handleKeyPress : Model -> ( Model, Cmd Msg )
handleKeyPress model =
    let
        keysDown =
            model.shared.keysDown

        doNothing =
            ( model, Cmd.none )

        tabPressed =
            KK.isOneKeyPressed KK.Tab keysDown

        shiftTabPressed =
            KK.isTwoKeysPressed KK.Tab KK.Shift keysDown

        -- Basic helper for handling tab/shift-tab situations.
        watchForTabAndShiftTab onTab onShiftTab =
            if tabPressed then
                ( model, onTab )
            else if shiftTabPressed then
                ( model, onShiftTab )
            else
                doNothing
    in
        case model.shared.route of
            Route.HomeComponentCreateBigbitName ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateBigbitDescription)
                    Cmd.none

            Route.HomeComponentCreateBigbitDescription ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateBigbitTags)
                    (Route.navigateTo Route.HomeComponentCreateBigbitName)

            Route.HomeComponentCreateBigbitTags ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.HomeComponentCreateBigbitCodeIntroduction Nothing)
                    (Route.navigateTo Route.HomeComponentCreateBigbitDescription)

            Route.HomeComponentCreateSnipbitName ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateSnipbitDescription)
                    (Cmd.none)

            Route.HomeComponentCreateSnipbitDescription ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateSnipbitLanguage)
                    (Route.navigateTo Route.HomeComponentCreateSnipbitName)

            Route.HomeComponentCreateSnipbitLanguage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateSnipbitTags)
                    (Route.navigateTo Route.HomeComponentCreateSnipbitDescription)

            Route.HomeComponentCreateSnipbitTags ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.HomeComponentCreateSnipbitCodeIntroduction)
                    (Route.navigateTo Route.HomeComponentCreateSnipbitLanguage)

            _ ->
                doNothing


{-| Logic for handling new key-release, all keys currently pressed available in
`shared.keysDown`.
-}
handleKeyRelease : KK.Key -> Model -> ( Model, Cmd Msg )
handleKeyRelease releasedKey model =
    ( model, Cmd.none )


{-| Gets the user from the API.
-}
getUser : () -> Cmd Msg
getUser () =
    Api.getAccount OnGetUserFailure OnGetUserSuccess


{-| Updates the model `route` field when the route is updated. This function
handles the cases where the user is logged in and goes to an unauth-page like
welcome or where the user isn't logged in and goes to an auth-page. You simply
need to specify `routesNotNeedingAuth`, `defaultUnauthRoute`, and
`defaultAuthRoute` in your `Routes` model. It also handles users going to
routes that don't exist (just goes `back` to the route they were on before).

Aside from auth logic, nothing else should be put here otherwise it gets
crowded. Trigger route hooks on the sub-components and let them hande the
logic.
-}
handleLocationChange : Maybe Route.Route -> Model -> ( Model, Cmd Msg )
handleLocationChange maybeRoute model =
    case maybeRoute of
        Nothing ->
            ( model, Navigation.back 1 )

        Just route ->
            let
                shared =
                    model.shared

                loggedIn =
                    Util.isNotNothing shared.user

                routeNeedsAuth =
                    not <| List.member route Route.routesNotNeedingAuth

                modelWithRoute route =
                    { model
                        | shared = { shared | route = route }
                    }

                -- Handle authentication logic here.
                ( newModel, newCmd ) =
                    case loggedIn of
                        False ->
                            case routeNeedsAuth of
                                -- not logged in, route doesn't need auth, good
                                False ->
                                    let
                                        newModel =
                                            modelWithRoute route
                                    in
                                        ( newModel, LocalStorage.saveModel newModel )

                                -- not logged in, route needs auth, bad - redirect.
                                True ->
                                    let
                                        newModel =
                                            modelWithRoute Route.defaultUnauthRoute

                                        newCmd =
                                            Cmd.batch
                                                [ Route.modifyTo newModel.shared.route
                                                , LocalStorage.saveModel newModel
                                                ]
                                    in
                                        ( newModel, newCmd )

                        True ->
                            case routeNeedsAuth of
                                -- logged in, route doesn't need auth, bad - redirect.
                                False ->
                                    let
                                        newModel =
                                            modelWithRoute Route.defaultAuthRoute

                                        newCmd =
                                            Cmd.batch
                                                [ Route.modifyTo newModel.shared.route
                                                , LocalStorage.saveModel newModel
                                                ]
                                    in
                                        ( newModel, newCmd )

                                -- logged in, route needs auth, good.
                                True ->
                                    let
                                        newModel =
                                            modelWithRoute route
                                    in
                                        ( newModel, LocalStorage.saveModel newModel )

                triggerRouteHookOnHomeComponent =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <| HomeMessage HomeMessages.OnRouteHit
                        ]
                    )
            in
                -- Handle general route-logic here, routes are a great way to be
                -- able to trigger certain things (hooks).
                case route of
                    -- Init the editor.
                    Route.HomeComponentCreateSnipbitCodeIntroduction ->
                        triggerRouteHookOnHomeComponent

                    -- Init the editor.
                    Route.HomeComponentCreateSnipbitCodeConclusion ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitCodeFrame _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewSnipbitIntroduction _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewSnipbitConclusion _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewSnipbitFrame _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewBigbitIntroduction _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewBigbitFrame _ _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewBigbitConclusion _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitName ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitDescription ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitLanguage ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitTags ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitName ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitDescription ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitTags ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeConclusion _ ->
                        triggerRouteHookOnHomeComponent

                    _ ->
                        ( newModel, newCmd )
