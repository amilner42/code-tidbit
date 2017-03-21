module Pages.Update exposing (update, updateCacheIf)

import Array
import Api
import Pages.Home.Update as HomeUpdate
import Pages.Home.Messages as HomeMessages
import Pages.Home.Model as HomeModel
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, updateKeysDown, updateKeysDownWithKeys, kkUpdateWrapper)
import Pages.Welcome.Update as WelcomeUpdate
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Keyboard.Extra as KK
import Models.Route as Route
import Models.ViewSnipbitData as ViewSnipbitData
import Models.ViewBigbitData as ViewBigbitData
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
                                        | route = Route.RegisterPage
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
            if
                ViewSnipbitData.isViewSnipbitRHCTabOpen
                    model.homeComponent.viewSnipbitData
            then
                doNothing
            else
                watchForLeftAndRightArrow onLeft onRight

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewBigbitWatchForLeftAndRightArrow onLeft onRight =
            if
                ViewBigbitData.isViewBigbitTutorialTabOpen
                    model.homeComponent.viewBigbitData.viewingBigbit
                    model.homeComponent.viewBigbitData.viewingBigbitRelevantHC
            then
                watchForLeftAndRightArrow onLeft onRight
            else
                doNothing
    in
        case model.shared.route of
            Route.CreateBigbitNamePage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateBigbitDescriptionPage)
                    Cmd.none

            Route.CreateBigbitDescriptionPage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateBigbitTagsPage)
                    (Route.navigateTo Route.CreateBigbitNamePage)

            Route.CreateBigbitTagsPage ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.CreateBigbitCodeIntroductionPage Nothing)
                    (Route.navigateTo Route.CreateBigbitDescriptionPage)

            Route.CreateSnipbitNamePage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateSnipbitDescriptionPage)
                    (Cmd.none)

            Route.CreateSnipbitDescriptionPage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateSnipbitLanguagePage)
                    (Route.navigateTo Route.CreateSnipbitNamePage)

            Route.CreateSnipbitLanguagePage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateSnipbitTagsPage)
                    (Route.navigateTo Route.CreateSnipbitDescriptionPage)

            Route.CreateSnipbitTagsPage ->
                watchForTabAndShiftTab
                    (Route.navigateTo Route.CreateSnipbitCodeIntroductionPage)
                    (Route.navigateTo Route.CreateSnipbitLanguagePage)

            Route.ViewSnipbitIntroductionPage fromStoryID mongoID ->
                viewSnipbitWatchForLeftAndRightArrow
                    Cmd.none
                    (Route.navigateTo <| Route.ViewSnipbitFramePage fromStoryID mongoID 1)

            Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                viewSnipbitWatchForLeftAndRightArrow
                    (Route.navigateTo <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber - 1))
                    (Route.navigateTo <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber + 1))

            Route.ViewSnipbitConclusionPage fromStoryID mongoID ->
                viewSnipbitWatchForLeftAndRightArrow
                    (Route.navigateTo <|
                        Route.ViewSnipbitFramePage
                            fromStoryID
                            mongoID
                            (model.homeComponent.viewSnipbitData.viewingSnipbit
                                |> maybeMapWithDefault (.highlightedComments >> Array.length) 0
                            )
                    )
                    Cmd.none

            Route.ViewBigbitIntroductionPage fromStoryID mongoID _ ->
                viewBigbitWatchForLeftAndRightArrow
                    Cmd.none
                    (Route.navigateTo <| Route.ViewBigbitFramePage fromStoryID mongoID 1 Nothing)

            Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
                viewBigbitWatchForLeftAndRightArrow
                    (Route.navigateTo <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber - 1) Nothing)
                    (Route.navigateTo <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber + 1) Nothing)

            Route.ViewBigbitConclusionPage fromStoryID mongoID _ ->
                viewBigbitWatchForLeftAndRightArrow
                    (Route.navigateTo <|
                        Route.ViewBigbitFramePage
                            fromStoryID
                            mongoID
                            (model.homeComponent.viewBigbitData.viewingBigbit
                                |> maybeMapWithDefault (.highlightedComments >> Array.length) 0
                            )
                            Nothing
                    )
                    Cmd.none

            Route.CreateStoryNamePage qpEditingStory ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.CreateStoryDescriptionPage qpEditingStory)
                    Cmd.none

            Route.CreateStoryDescriptionPage qpEditingStory ->
                watchForTabAndShiftTab
                    (Route.navigateTo <| Route.CreateStoryTagsPage qpEditingStory)
                    (Route.navigateTo <| Route.CreateStoryNamePage qpEditingStory)

            Route.CreateStoryTagsPage qpEditingStory ->
                watchForTabAndShiftTab
                    Cmd.none
                    (Route.navigateTo <| Route.CreateStoryDescriptionPage qpEditingStory)

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
                    Route.CreatePage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitCodeIntroductionPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitCodeConclusionPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitCodeFramePage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewSnipbitIntroductionPage _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewSnipbitConclusionPage _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewSnipbitFramePage _ _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewBigbitIntroductionPage _ _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewBigbitFramePage _ _ _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewBigbitConclusionPage _ _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.ViewStoryPage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitNamePage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitDescriptionPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitLanguagePage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateSnipbitTagsPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitNamePage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitDescriptionPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitTagsPage ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitCodeIntroductionPage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitCodeFramePage _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateBigbitCodeConclusionPage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateStoryNamePage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateStoryDescriptionPage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.CreateStoryTagsPage _ ->
                        triggerRouteHookOnHomeComponent

                    Route.DevelopStoryPage _ ->
                        triggerRouteHookOnHomeComponent

                    _ ->
                        ( newModel, newCmd )
