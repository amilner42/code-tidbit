module Pages.Update exposing (update, updateCacheIf)

import Api
import Array
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Keyboard.Extra as KK
import Models.Route as Route
import Navigation
import Pages.Create.Messages as CreateMessages
import Pages.Create.Update as CreateUpdate
import Pages.CreateBigbit.Messages as CreateBigbitMessages
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateBigbit.Update as CreateBigbitUpdate
import Pages.CreateSnipbit.Messages as CreateSnipbitMessages
import Pages.CreateSnipbit.Update as CreateSnipbitUpdate
import Pages.DevelopStory.Messages as DevelopStoryMessages
import Pages.DevelopStory.Update as DevelopStoryUpdate
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, updateKeysDown, updateKeysDownWithKeys, kkUpdateWrapper)
import Pages.NewStory.Messages as NewStoryMessages
import Pages.NewStory.Update as NewStoryUpdate
import Pages.Profile.Messages as ProfileMessages
import Pages.Profile.Update as ProfileUpdate
import Pages.ViewBigbit.Messages as ViewBigbitMessages
import Pages.ViewBigbit.Model as ViewBigbitModel
import Pages.ViewBigbit.Update as ViewBigbitUpdate
import Pages.ViewSnipbit.Messages as ViewSnipbitMessages
import Pages.ViewSnipbit.Model as ViewSnipbitModel
import Pages.ViewSnipbit.Update as ViewSnipbitUpdate
import Pages.ViewStory.Messages as ViewStoryMessages
import Pages.ViewStory.Update as ViewStoryUpdate
import Pages.Welcome.Update as WelcomeUpdate
import Ports
import Task


{-| `Base` update.
-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    updateCacheIf msg model True


{-| Wrapper around `update` allowing to cache the model in local storage.

NOTE: Sometimes we don't want to save to the cache, for example when the website originally loads if we save to cache we
      end up loading what we saved (the default model) instead of what was in there before. As well, we may in the
      future allow users to turn off automatic cacheing, so this function easily allows to control that.
-}
updateCacheIf : Msg -> Model -> Bool -> ( Model, Cmd Msg )
updateCacheIf msg model shouldCache =
    let
        shared =
            model.shared

        doNothing =
            ( model, Cmd.none )

        ( newModel, newCmd ) =
            case msg of
                NoOp ->
                    doNothing

                GoTo route ->
                    ( model, Route.navigateTo route )

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

                WelcomeMessage subMsg ->
                    let
                        ( newWelcomeModel, newShared, newSubMsg ) =
                            WelcomeUpdate.update
                                subMsg
                                model.welcomePage
                                model.shared

                        newModel =
                            { model
                                | welcomePage = newWelcomeModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map WelcomeMessage newSubMsg )

                ViewSnipbitMessage subMsg ->
                    let
                        ( newViewSnipbitModel, newShared, newSubMsg ) =
                            ViewSnipbitUpdate.update
                                subMsg
                                model.viewSnipbitPage
                                model.shared

                        newModel =
                            { model
                                | viewSnipbitPage = newViewSnipbitModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map ViewSnipbitMessage newSubMsg )

                ViewBigbitMessage subMsg ->
                    let
                        ( newViewBigbitModel, newShared, newSubMsg ) =
                            ViewBigbitUpdate.update
                                subMsg
                                model.viewBigbitPage
                                model.shared

                        newModel =
                            { model
                                | viewBigbitPage = newViewBigbitModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map ViewBigbitMessage newSubMsg )

                ViewStoryMessage subMsg ->
                    let
                        ( newShared, newSubMsg ) =
                            ViewStoryUpdate.update
                                subMsg
                                model.shared

                        newModel =
                            { model
                                | shared = newShared
                            }
                    in
                        ( newModel, Cmd.map ViewStoryMessage newSubMsg )

                ProfileMessage subMsg ->
                    let
                        ( newProfileModel, newShared, newSubMsg ) =
                            ProfileUpdate.update
                                subMsg
                                model.profilePage
                                model.shared

                        newModel =
                            { model
                                | profilePage = newProfileModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map ProfileMessage newSubMsg )

                NewStoryMessage subMsg ->
                    let
                        ( newNewStoryModel, newShared, newSubMsg ) =
                            NewStoryUpdate.update
                                subMsg
                                model.newStoryPage
                                model.shared

                        newModel =
                            { model
                                | newStoryPage = newNewStoryModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map NewStoryMessage newSubMsg )

                CreateMessage subMsg ->
                    let
                        ( newCreateModel, newShared, newSubMsg ) =
                            CreateUpdate.update
                                subMsg
                                model.createPage
                                model.shared

                        newModel =
                            { model
                                | createPage = newCreateModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map CreateMessage newSubMsg )

                DevelopStoryMessage subMsg ->
                    let
                        ( newDevelopStoryModel, newShared, newSubMsg ) =
                            DevelopStoryUpdate.update
                                subMsg
                                model.developStoryPage
                                model.shared

                        newModel =
                            { model
                                | developStoryPage = newDevelopStoryModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map DevelopStoryMessage newSubMsg )

                CreateSnipbitMessage subMsg ->
                    let
                        ( newCreateSnipbitModel, newShared, newSubMsg ) =
                            CreateSnipbitUpdate.update
                                subMsg
                                model.createSnipbitPage
                                model.shared

                        newModel =
                            { model
                                | createSnipbitPage = newCreateSnipbitModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map CreateSnipbitMessage newSubMsg )

                CreateBigbitMessage subMsg ->
                    let
                        ( newCreateBigbitModel, newShared, newSubMsg ) =
                            CreateBigbitUpdate.update
                                subMsg
                                model.createBigbitPage
                                model.shared

                        newModel =
                            { model
                                | createBigbitPage = newCreateBigbitModel
                                , shared = newShared
                            }
                    in
                        ( newModel, Cmd.map CreateBigbitMessage newSubMsg )

                CodeEditorUpdate { id, value, deltaRange, action } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            (updateCacheIf
                                (CreateSnipbitMessage <|
                                    CreateSnipbitMessages.OnUpdateCode
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
                                (CreateBigbitMessage <|
                                    CreateBigbitMessages.OnUpdateCode
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
                                (CreateSnipbitMessage <|
                                    CreateSnipbitMessages.OnRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "create-bigbit-code-editor" ->
                            (updateCacheIf
                                (CreateBigbitMessage <|
                                    CreateBigbitMessages.OnRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "view-snipbit-code-editor" ->
                            (updateCacheIf
                                (ViewSnipbitMessage <|
                                    ViewSnipbitMessages.OnRangeSelected range
                                )
                                model
                                shouldCache
                            )

                        "view-bigbit-code-editor" ->
                            (updateCacheIf
                                (ViewBigbitMessage <|
                                    ViewBigbitMessages.OnRangeSelected range
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
                        -- Key held, but no new key clicked. Get rid of this if we need hotkeys with key-holds.
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


{-| Logic for handling new key-press, all keys currently pressed exist in `shared.keysDown`.

NOTE: This doesn't require that a specific element be focussed, put logic for route hotkeys here, if you want a hotkey
      only if a certain element is focussed, stick to putting that on the element itself.
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
                ViewSnipbitModel.isViewSnipbitRHCTabOpen
                    model.viewSnipbitPage
            then
                doNothing
            else
                watchForLeftAndRightArrow onLeft onRight

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewBigbitWatchForLeftAndRightArrow onLeft onRight =
            if
                ViewBigbitModel.isBigbitTutorialTabOpen
                    model.viewBigbitPage.bigbit
                    model.viewBigbitPage.relevantHC
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
                            (model.viewSnipbitPage.snipbit
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
                            (model.viewBigbitPage.bigbit
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


{-| Logic for handling new key-release, all keys currently pressed available in `shared.keysDown`.
-}
handleKeyRelease : KK.Key -> Model -> ( Model, Cmd Msg )
handleKeyRelease releasedKey model =
    ( model, Cmd.none )


{-| Gets the user from the API.
-}
getUser : () -> Cmd Msg
getUser () =
    Api.getAccount OnGetUserFailure OnGetUserSuccess


{-| Updates the model `route` field when the route is updated. This function handles the cases where the user is logged
in and goes to an unauth-page like welcome or where the user isn't logged in and goes to an auth-page. You simply need
to specify `routesNotNeedingAuth`, `defaultUnauthRoute`, and `defaultAuthRoute` in your `Routes` model. It also handles
users going to routes that don't exist (just goes `back` to the route they were on before).

Aside from auth logic, nothing else should be put here otherwise it gets crowded. Trigger route hooks on the sub-pages
and let them hande the logic.
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

                triggerRouteHookOnViewSnipbitPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            ViewSnipbitMessage <|
                                ViewSnipbitMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnViewBigbitPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            ViewBigbitMessage <|
                                ViewBigbitMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnViewStoryPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            ViewStoryMessage <|
                                ViewStoryMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnNewStoryPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            NewStoryMessage <|
                                NewStoryMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnCreatePage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            CreateMessage <|
                                CreateMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnDevelopStoryPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            DevelopStoryMessage <|
                                DevelopStoryMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnCreateSnipbitPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            CreateSnipbitMessage <|
                                CreateSnipbitMessages.OnRouteHit route
                        ]
                    )

                triggerRouteHookOnCreateBigbitPage =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg <|
                            CreateBigbitMessage <|
                                CreateBigbitMessages.OnRouteHit route
                        ]
                    )
            in
                -- Handle general route-logic here, routes are a great way to be
                -- able to trigger certain things (hooks).
                case route of
                    Route.CreatePage ->
                        triggerRouteHookOnCreatePage

                    Route.ViewSnipbitIntroductionPage _ _ ->
                        triggerRouteHookOnViewSnipbitPage

                    Route.ViewSnipbitConclusionPage _ _ ->
                        triggerRouteHookOnViewSnipbitPage

                    Route.ViewSnipbitFramePage _ _ _ ->
                        triggerRouteHookOnViewSnipbitPage

                    Route.ViewBigbitIntroductionPage _ _ _ ->
                        triggerRouteHookOnViewBigbitPage

                    Route.ViewBigbitFramePage _ _ _ _ ->
                        triggerRouteHookOnViewBigbitPage

                    Route.ViewBigbitConclusionPage _ _ _ ->
                        triggerRouteHookOnViewBigbitPage

                    Route.ViewStoryPage _ ->
                        triggerRouteHookOnViewStoryPage

                    Route.CreateSnipbitNamePage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitDescriptionPage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitLanguagePage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitTagsPage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitCodeIntroductionPage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitCodeConclusionPage ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateSnipbitCodeFramePage _ ->
                        triggerRouteHookOnCreateSnipbitPage

                    Route.CreateBigbitNamePage ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateBigbitDescriptionPage ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateBigbitTagsPage ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateBigbitCodeIntroductionPage _ ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateBigbitCodeFramePage _ _ ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateBigbitCodeConclusionPage _ ->
                        triggerRouteHookOnCreateBigbitPage

                    Route.CreateStoryNamePage _ ->
                        triggerRouteHookOnNewStoryPage

                    Route.CreateStoryDescriptionPage _ ->
                        triggerRouteHookOnNewStoryPage

                    Route.CreateStoryTagsPage _ ->
                        triggerRouteHookOnNewStoryPage

                    Route.DevelopStoryPage _ ->
                        triggerRouteHookOnDevelopStoryPage

                    _ ->
                        ( newModel, newCmd )
