module Components.Update exposing (update, updateCacheIf)

import Array
import Api
import Components.Home.Update as HomeUpdate
import Components.Home.Messages as HomeMessages
import Components.Home.Model as HomeModel
import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model, updateKeysDown, updateKeysDownWithKeys, kkUpdateWrapper)
import Components.Welcome.Update as WelcomeUpdate
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
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

                CodeEditorUpdate { id, value, deltaRange, action } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.SnipbitUpdateCode
                                        { newCode = value
                                        , deltaRange = deltaRange
                                        , action = action
                                        }
                                )
                                model
                                shouldCache
                            )

                        "create-bigbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.BigbitUpdateCode
                                        { newCode = value
                                        , deltaRange = deltaRange
                                        , action = action
                                        }
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

        leftArrowPressed =
            KK.isOneKeyPressed KK.ArrowLeft keysDown

        rightArrowPressed =
            KK.isOneKeyPressed KK.ArrowRight keysDown

        -- Basic helper for handling tab/shift-tab situations.
        watchForTabAndShiftTab onTab onShiftTab =
            if tabPressed then
                ( model, onTab )
            else if shiftTabPressed then
                ( model, onShiftTab )
            else
                doNothing

        -- Basic helper for left/right arrow situations.
        watchForLeftAndRightArrow onLeft onRight =
            if leftArrowPressed then
                ( model, onLeft )
            else if rightArrowPressed then
                ( model, onRight )
            else
                doNothing

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewSnipbitWatchForLeftAndRightArrow onLeft onRight =
            if HomeModel.isViewSnipbitRHCTabOpen model.homeComponent then
                doNothing
            else
                watchForLeftAndRightArrow onLeft onRight

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewBigbitWatchForLeftAndRightArrow onLeft onRight =
            if
                HomeModel.isViewBigbitTutorialTabOpen
                    model.homeComponent.viewingBigbit
                    model.homeComponent.viewingBigbitRelevantHC
            then
                watchForLeftAndRightArrow onLeft onRight
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

            Route.HomeComponentViewSnipbitIntroduction mongoID ->
                viewSnipbitWatchForLeftAndRightArrow
                    Cmd.none
                    (Route.navigateTo <| Route.HomeComponentViewSnipbitFrame mongoID 1)

            Route.HomeComponentViewSnipbitFrame mongoID frameNumber ->
                viewSnipbitWatchForLeftAndRightArrow
                    (Route.navigateTo <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber - 1))
                    (Route.navigateTo <| Route.HomeComponentViewSnipbitFrame mongoID (frameNumber + 1))

            Route.HomeComponentViewSnipbitConclusion mongoID ->
                viewSnipbitWatchForLeftAndRightArrow
                    (Route.navigateTo <|
                        Route.HomeComponentViewSnipbitFrame
                            mongoID
                            (model.homeComponent.viewingSnipbit
                                |> maybeMapWithDefault (.highlightedComments >> Array.length) 0
                            )
                    )
                    Cmd.none

            Route.HomeComponentViewBigbitIntroduction mongoID _ ->
                viewBigbitWatchForLeftAndRightArrow
                    Cmd.none
                    (Route.navigateTo <| Route.HomeComponentViewBigbitFrame mongoID 1 Nothing)

            Route.HomeComponentViewBigbitFrame mongoID frameNumber _ ->
                viewBigbitWatchForLeftAndRightArrow
                    (Route.navigateTo <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber - 1) Nothing)
                    (Route.navigateTo <| Route.HomeComponentViewBigbitFrame mongoID (frameNumber + 1) Nothing)

            Route.HomeComponentViewBigbitConclusion mongoID _ ->
                viewBigbitWatchForLeftAndRightArrow
                    (Route.navigateTo <|
                        Route.HomeComponentViewBigbitFrame
                            mongoID
                            (model.homeComponent.viewingBigbit
                                |> maybeMapWithDefault (.highlightedComments >> Array.length) 0
                            )
                            Nothing
                    )
                    Cmd.none

            Route.HomeComponentCreateNewStoryName qpEditingStory ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.HomeComponentCreateNewStoryDescription qpEditingStory)
                    Cmd.none

            Route.HomeComponentCreateNewStoryDescription qpEditingStory ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.HomeComponentCreateNewStoryTags qpEditingStory)
                    (Route.navigateTo <| Route.HomeComponentCreateNewStoryName qpEditingStory)

            Route.HomeComponentCreateNewStoryTags qpEditingStory ->
                watchForTabAndShiftTab
                    Cmd.none
                    (Route.navigateTo <| Route.HomeComponentCreateNewStoryDescription qpEditingStory)

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

                modelWithRoute route =
                    { model
                        | shared = { shared | route = route }
                    }

                -- Handle authentication logic here.
                ( newModel, newCmd ) =
                    case loggedIn of
                        False ->
                            case Route.routeRequiresAuth route of
                                False ->
                                    let
                                        newModel =
                                            modelWithRoute route
                                    in
                                        ( newModel, LocalStorage.saveModel newModel )

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
                            case Route.routeRequiresNotAuth route of
                                False ->
                                    let
                                        newModel =
                                            modelWithRoute route
                                    in
                                        ( newModel, LocalStorage.saveModel newModel )

                                True ->
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
                    Route.HomeComponentCreate ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateSnipbitCodeIntroduction ->
                        triggerRouteHookOnHomeComponent

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

                    Route.HomeComponentViewStory _ ->
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

                    Route.HomeComponentCreateNewStoryName _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateNewStoryDescription _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateNewStoryTags _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateStory _ ->
                        triggerRouteHookOnHomeComponent

                    _ ->
                        ( newModel, newCmd )
