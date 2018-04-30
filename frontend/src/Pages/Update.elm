module Pages.Update exposing (update, updateCacheIf)

import Api
import Array
import DefaultServices.CommonSubPageUtil exposing (commonSubPageUtil)
import DefaultServices.InfixFunctions exposing (..)
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Keyboard.Extra as KK
import Models.Route as Route
import Navigation
import Pages.Browse.Messages as BrowseMessages
import Pages.Browse.Update as BrowseUpdate
import Pages.Create.Messages as CreateMessages
import Pages.Create.Update as CreateUpdate
import Pages.CreateBigbit.Messages as CreateBigbitMessages
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateBigbit.Update as CreateBigbitUpdate
import Pages.CreateSnipbit.Messages as CreateSnipbitMessages
import Pages.CreateSnipbit.Update as CreateSnipbitUpdate
import Pages.DefaultModel exposing (defaultModel)
import Pages.DevelopStory.Messages as DevelopStoryMessages
import Pages.DevelopStory.Update as DevelopStoryUpdate
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, updateKeysDown)
import Pages.NewStory.Messages as NewStoryMessages
import Pages.NewStory.Update as NewStoryUpdate
import Pages.Notifications.Messages as NotificationsMessages
import Pages.Notifications.Update as NotificationsUpdate
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
import Pages.Welcome.Messages as WelcomeMessages
import Pages.Welcome.Update as WelcomeUpdate
import Ports


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

        api =
            Api.api shared.flags.apiBaseUrl

        getUserAndThenRefresh () =
            api.get.account OnGetUserAndThenRefreshFailure OnGetUserAndThenRefreshSuccess

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

                        ( newModel, newCmd ) =
                            handleLocationChange newRoute model
                    in
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Ports.gaPageView <| googleAnalyticsPageName newRoute
                        ]
                    )

                LoadModelFromLocalStorage ->
                    ( model, LocalStorage.loadModel () )

                OnLoadModelFromLocalStorageSuccess newModel ->
                    {- If the state was properly cached in localStorage, we simply load the cached model and refresh
                       the page to trigger route hooks.
                    -}
                    ( newModel, Route.modifyTo shared.route )

                OnLoadModelFromLocalStorageFailure err ->
                    {- If the state wasn't cached in localStorage, we attempt to get the user (for the narrow
                       use-case where they have the cookies to be logged in but they cleared their localStorage), and
                       then regardless we trigger a page refresh to trigger route hooks.
                    -}
                    ( model, getUserAndThenRefresh () )

                OnGetUserAndThenRefreshSuccess user ->
                    let
                        newModel =
                            { model | shared = { shared | user = Just user } }
                    in
                    ( newModel, Route.modifyTo shared.route )

                OnGetUserAndThenRefreshFailure newApiError ->
                    ( model, Route.modifyTo shared.route )

                WelcomeMessage subMsg ->
                    let
                        ( newWelcomeModel, newShared, newSubMsg ) =
                            WelcomeUpdate.update
                                (commonSubPageUtil model.welcomePage model.shared)
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
                                (commonSubPageUtil model.viewSnipbitPage model.shared)
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
                                (commonSubPageUtil model.viewBigbitPage model.shared)
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
                        ( newViewStoryModel, newShared, newSubMsg ) =
                            ViewStoryUpdate.update
                                (commonSubPageUtil model.viewStoryPage model.shared)
                                subMsg
                                model.viewStoryPage
                                model.shared

                        newModel =
                            { model
                                | viewStoryPage = newViewStoryModel
                                , shared = newShared
                            }
                    in
                    ( newModel, Cmd.map ViewStoryMessage newSubMsg )

                ProfileMessage subMsg ->
                    let
                        ( newProfileModel, newShared, newSubMsg ) =
                            ProfileUpdate.update
                                (commonSubPageUtil model.profilePage model.shared)
                                subMsg
                                model.profilePage
                                model.shared

                        justLoggedOut =
                            case subMsg of
                                ProfileMessages.OnLogOutSuccess _ ->
                                    True

                                _ ->
                                    False

                        newModel =
                            if justLoggedOut then
                                defaultModel newShared.route newShared.flags
                            else
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
                                (commonSubPageUtil model.newStoryPage model.shared)
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
                                (commonSubPageUtil model.createPage model.shared)
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
                                (commonSubPageUtil model.developStoryPage model.shared)
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
                                (commonSubPageUtil model.createSnipbitPage model.shared)
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
                                (commonSubPageUtil model.createBigbitPage model.shared)
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

                BrowseMessage subMsg ->
                    let
                        ( newBrowsePageModel, newShared, newSubMsg ) =
                            BrowseUpdate.update
                                (commonSubPageUtil model.browsePage model.shared)
                                subMsg
                                model.browsePage
                                model.shared

                        newModel =
                            { model
                                | browsePage = newBrowsePageModel
                                , shared = newShared
                            }
                    in
                    ( newModel, Cmd.map BrowseMessage newSubMsg )

                NotificationsMessage subMsg ->
                    let
                        ( newNotificationsPageModel, newShared, newSubMsg ) =
                            NotificationsUpdate.update
                                (commonSubPageUtil model.notificationsPage model.shared)
                                subMsg
                                model.notificationsPage
                                model.shared

                        newModel =
                            { model
                                | notificationsPage = newNotificationsPageModel
                                , shared = newShared
                            }
                    in
                    ( newModel, Cmd.map NotificationsMessage newSubMsg )

                CodeEditorUpdate { id, value, deltaRange, action } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            updateCacheIf
                                (CreateSnipbitMessage <|
                                    CreateSnipbitMessages.OnUpdateCode
                                        { newCode = value
                                        , deltaRange = deltaRange
                                        , action = action
                                        }
                                )
                                model
                                shouldCache

                        "create-bigbit-code-editor" ->
                            updateCacheIf
                                (CreateBigbitMessage <|
                                    CreateBigbitMessages.OnUpdateCode
                                        { newCode = value
                                        , deltaRange = deltaRange
                                        , action = action
                                        }
                                )
                                model
                                shouldCache

                        _ ->
                            doNothing

                CodeEditorSelectionUpdate { id, range } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            updateCacheIf
                                (CreateSnipbitMessage <| CreateSnipbitMessages.OnRangeSelected range)
                                model
                                shouldCache

                        "create-bigbit-code-editor" ->
                            updateCacheIf
                                (CreateBigbitMessage <| CreateBigbitMessages.OnRangeSelected range)
                                model
                                shouldCache

                        "view-snipbit-code-editor" ->
                            updateCacheIf
                                (ViewSnipbitMessage <| ViewSnipbitMessages.OnRangeSelected range)
                                model
                                shouldCache

                        "view-bigbit-code-editor" ->
                            updateCacheIf
                                (ViewBigbitMessage <| ViewBigbitMessages.OnRangeSelected range)
                                model
                                shouldCache

                        _ ->
                            doNothing

                KeyboardExtraMessage msg ->
                    let
                        newKeysDown =
                            KK.update msg model.shared.keysDown

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

                CloseErrorModal ->
                    ( { model | shared = { shared | apiModalError = Nothing } }
                    , Cmd.none
                    )

                CloseSignUpModal ->
                    ( { model | shared = { shared | userNeedsAuthModal = Nothing } }
                    , Cmd.none
                    )
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

        -- Basic helper for handling ctrl-, ctrl-. situations.
        watchForControlPeriodAndControlComma onControlEquals onControlMinus =
            KK.getHotkeyAction
                [ ( [ KK.Control, KK.Period ], onControlEquals )
                , ( [ KK.Control, KK.Comma ], onControlMinus )
                ]
                keysDown
                ?> doNothing

        -- Basic helper for handling tab/shift-tab situations.
        watchForTabAndShiftTab onTab onShiftTab =
            KK.getHotkeyAction
                [ ( [ KK.Tab ], ( model, onTab ) )
                , ( [ KK.Tab, KK.Shift ], ( model, onShiftTab ) )
                ]
                keysDown
                ?> doNothing

        -- Basic helper for left/right arrow situations.
        watchForLeftAndRightArrow onLeft onRight =
            KK.getHotkeyAction
                [ ( [ KK.ArrowLeft ], ( model, onLeft ) )
                , ( [ KK.ArrowRight ], ( model, onRight ) )
                ]
                keysDown
                ?> doNothing

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewSnipbitWatchForLeftAndRightArrow onLeft onRight =
            if ViewSnipbitModel.isViewSnipbitRHCTabOpen model.viewSnipbitPage then
                doNothing
            else
                watchForLeftAndRightArrow onLeft onRight

        -- Makes sure to only activate arrow keys if in the tutorial.
        viewBigbitWatchForLeftAndRightArrow onLeft onRight =
            if ViewBigbitModel.isBigbitRHCTabOpen model.viewBigbitPage.relevantHC then
                doNothing
            else
                watchForLeftAndRightArrow onLeft onRight
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
                (Util.cmdFromMsg <| CreateBigbitMessage CreateBigbitMessages.GoToCodeTab)
                (Route.navigateTo Route.CreateBigbitDescriptionPage)

        Route.CreateBigbitCodeFramePage frameNumber _ ->
            if model.createBigbitPage.previewMarkdown then
                watchForLeftAndRightArrow
                    (if frameNumber == 1 then
                        Cmd.none
                     else
                        Route.navigateTo <|
                            Route.CreateBigbitCodeFramePage (frameNumber - 1) <|
                                CreateBigbitModel.getActiveFileForFrame (frameNumber - 1) model.createBigbitPage
                    )
                    (if frameNumber == Array.length model.createBigbitPage.highlightedComments then
                        Cmd.none
                     else
                        Route.navigateTo <|
                            Route.CreateBigbitCodeFramePage (frameNumber + 1) <|
                                CreateBigbitModel.getActiveFileForFrame (frameNumber + 1) model.createBigbitPage
                    )
            else
                watchForControlPeriodAndControlComma
                    (update (CreateBigbitMessage CreateBigbitMessages.AddFrame) model)
                    (update (CreateBigbitMessage CreateBigbitMessages.RemoveFrame) model)

        Route.CreateSnipbitNamePage ->
            watchForTabAndShiftTab
                (Route.navigateTo Route.CreateSnipbitDescriptionPage)
                Cmd.none

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
                (Util.cmdFromMsg <| CreateSnipbitMessage CreateSnipbitMessages.GoToCodeTab)
                (Route.navigateTo Route.CreateSnipbitLanguagePage)

        Route.CreateSnipbitCodeFramePage frameNumber ->
            if model.createSnipbitPage.previewMarkdown then
                watchForLeftAndRightArrow
                    (if frameNumber == 1 then
                        Cmd.none
                     else
                        Route.navigateTo <| Route.CreateSnipbitCodeFramePage <| frameNumber - 1
                    )
                    (if frameNumber == Array.length model.createSnipbitPage.highlightedComments then
                        Cmd.none
                     else
                        Route.navigateTo <| Route.CreateSnipbitCodeFramePage <| frameNumber + 1
                    )
            else
                watchForControlPeriodAndControlComma
                    (update (CreateSnipbitMessage CreateSnipbitMessages.AddFrame) model)
                    (update (CreateSnipbitMessage CreateSnipbitMessages.RemoveFrame) model)

        Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
            viewSnipbitWatchForLeftAndRightArrow
                (Route.navigateTo <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber - 1))
                (Route.navigateTo <| Route.ViewSnipbitFramePage fromStoryID mongoID (frameNumber + 1))

        Route.ViewBigbitFramePage fromStoryID mongoID frameNumber _ ->
            viewBigbitWatchForLeftAndRightArrow
                (Route.navigateTo <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber - 1) Nothing)
                (Route.navigateTo <| Route.ViewBigbitFramePage fromStoryID mongoID (frameNumber + 1) Nothing)

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
                                    in
                                    ( newModel
                                    , Cmd.batch
                                        [ Route.modifyTo newModel.shared.route
                                        , LocalStorage.saveModel newModel
                                        ]
                                    )

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
                                    in
                                    ( newModel
                                    , Cmd.batch
                                        [ Route.modifyTo newModel.shared.route
                                        , LocalStorage.saveModel newModel
                                        ]
                                    )

                triggerRouteHook withMsg =
                    ( newModel
                    , Cmd.batch
                        [ newCmd
                        , Util.cmdFromMsg withMsg
                        ]
                    )

                triggerRouteHookOnWelcomePage =
                    triggerRouteHook <| WelcomeMessage <| WelcomeMessages.OnRouteHit route

                triggerRouteHookOnViewSnipbitPage =
                    triggerRouteHook <| ViewSnipbitMessage <| ViewSnipbitMessages.OnRouteHit route

                triggerRouteHookOnViewBigbitPage =
                    triggerRouteHook <| ViewBigbitMessage <| ViewBigbitMessages.OnRouteHit route

                triggerRouteHookOnViewStoryPage =
                    triggerRouteHook <| ViewStoryMessage <| ViewStoryMessages.OnRouteHit route

                triggerRouteHookOnNewStoryPage =
                    triggerRouteHook <| NewStoryMessage <| NewStoryMessages.OnRouteHit route

                triggerRouteHookOnCreatePage =
                    triggerRouteHook <| CreateMessage <| CreateMessages.OnRouteHit route

                triggerRouteHookOnDevelopStoryPage =
                    triggerRouteHook <| DevelopStoryMessage <| DevelopStoryMessages.OnRouteHit route

                triggerRouteHookOnCreateSnipbitPage =
                    triggerRouteHook <| CreateSnipbitMessage <| CreateSnipbitMessages.OnRouteHit route

                triggerRouteHookOnCreateBigbitPage =
                    triggerRouteHook <| CreateBigbitMessage <| CreateBigbitMessages.OnRouteHit route

                triggerRouteHookOnBrowsePage =
                    triggerRouteHook <| BrowseMessage <| BrowseMessages.OnRouteHit route

                triggerRouteHookOnNotificationsPage =
                    triggerRouteHook <| NotificationsMessage <| NotificationsMessages.OnRouteHit route
            in
            -- Handle general route-logic here, routes are a great way to be
            -- able to trigger certain things (hooks).
            case route of
                Route.LoginPage _ ->
                    triggerRouteHookOnWelcomePage

                Route.RegisterPage _ ->
                    triggerRouteHookOnWelcomePage

                Route.BrowsePage ->
                    triggerRouteHookOnBrowsePage

                Route.CreatePage ->
                    triggerRouteHookOnCreatePage

                Route.ViewSnipbitFramePage _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitQuestionsPage _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitQuestionPage _ _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitAnswersPage _ _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitAnswerPage _ _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitQuestionCommentsPage _ _ _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitAnswerCommentsPage _ _ _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitAskQuestion _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitAnswerQuestion _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitEditQuestion _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewSnipbitEditAnswer _ _ _ ->
                    triggerRouteHookOnViewSnipbitPage

                Route.ViewBigbitFramePage _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitQuestionsPage _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitQuestionPage _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitAnswersPage _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitAnswerPage _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitQuestionCommentsPage _ _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitAnswerCommentsPage _ _ _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitAskQuestion _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitEditQuestion _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitAnswerQuestion _ _ _ ->
                    triggerRouteHookOnViewBigbitPage

                Route.ViewBigbitEditAnswer _ _ _ ->
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

                Route.CreateSnipbitCodeFramePage _ ->
                    triggerRouteHookOnCreateSnipbitPage

                Route.CreateBigbitNamePage ->
                    triggerRouteHookOnCreateBigbitPage

                Route.CreateBigbitDescriptionPage ->
                    triggerRouteHookOnCreateBigbitPage

                Route.CreateBigbitTagsPage ->
                    triggerRouteHookOnCreateBigbitPage

                Route.CreateBigbitCodeFramePage _ _ ->
                    triggerRouteHookOnCreateBigbitPage

                Route.CreateStoryNamePage _ ->
                    triggerRouteHookOnNewStoryPage

                Route.CreateStoryDescriptionPage _ ->
                    triggerRouteHookOnNewStoryPage

                Route.CreateStoryTagsPage _ ->
                    triggerRouteHookOnNewStoryPage

                Route.DevelopStoryPage _ ->
                    triggerRouteHookOnDevelopStoryPage

                Route.NotificationsPage ->
                    triggerRouteHookOnNotificationsPage

                _ ->
                    ( newModel, newCmd )


{-| Gets the page name to be used in GA from the current route.
-}
googleAnalyticsPageName : Maybe Route.Route -> String
googleAnalyticsPageName maybeRoute =
    case maybeRoute of
        Nothing ->
            "invalid-route"

        Just Route.BrowsePage ->
            "browse-page"

        Just (Route.ViewSnipbitFramePage _ _ _) ->
            "view-snipbit-frame"

        Just (Route.ViewSnipbitQuestionsPage _ _) ->
            "view-snipbit-qa"

        Just (Route.ViewSnipbitQuestionPage _ _ _ _) ->
            "view-snipbit-qa-question"

        Just (Route.ViewSnipbitAnswersPage _ _ _ _) ->
            "view-snipbit-qa-answers"

        Just (Route.ViewSnipbitAnswerPage _ _ _ _) ->
            "view-snipbit-qa-answer"

        Just (Route.ViewSnipbitQuestionCommentsPage _ _ _ _ _) ->
            "view-snipbit-qa-question-comments"

        Just (Route.ViewSnipbitAnswerCommentsPage _ _ _ _ _) ->
            "view-snipbit-qa-answer-comments"

        Just (Route.ViewSnipbitAskQuestion _ _) ->
            "view-snipbit-qa-ask"

        Just (Route.ViewSnipbitAnswerQuestion _ _ _) ->
            "view-snipbit-qa-answer-question"

        Just (Route.ViewSnipbitEditQuestion _ _ _) ->
            "view-snipbit-qa-edit-question"

        Just (Route.ViewSnipbitEditAnswer _ _ _) ->
            "view-snipbit-qa-edit-answer"

        Just (Route.ViewBigbitFramePage _ _ _ _) ->
            "view-bigbit-frame"

        Just (Route.ViewBigbitQuestionsPage _ _) ->
            "view-bigbit-qa"

        Just (Route.ViewBigbitQuestionPage _ _ _ _) ->
            "view-bigbit-qa-question"

        Just (Route.ViewBigbitAnswersPage _ _ _ _) ->
            "view-bigbit-qa-answers"

        Just (Route.ViewBigbitAnswerPage _ _ _ _) ->
            "view-bigbit-qa-answer"

        Just (Route.ViewBigbitQuestionCommentsPage _ _ _ _ _) ->
            "view-bigbit-qa-question-comments"

        Just (Route.ViewBigbitAnswerCommentsPage _ _ _ _ _) ->
            "view-bigbit-qa-answer-comments"

        Just (Route.ViewBigbitAskQuestion _ _) ->
            "view-bigbit-qa-ask"

        Just (Route.ViewBigbitEditQuestion _ _ _) ->
            "view-bigbit-qa-edit-question"

        Just (Route.ViewBigbitAnswerQuestion _ _ _) ->
            "view-bigbit-qa-answer-question"

        Just (Route.ViewBigbitEditAnswer _ _ _) ->
            "view-bigbit-qa-edit-answer"

        Just (Route.ViewStoryPage _) ->
            "view-story"

        Just Route.CreatePage ->
            "create"

        Just Route.CreateSnipbitNamePage ->
            "create-snipbit"

        Just Route.CreateSnipbitDescriptionPage ->
            "create-snipbit"

        Just Route.CreateSnipbitLanguagePage ->
            "create-snipbit"

        Just Route.CreateSnipbitTagsPage ->
            "create-snipbit"

        Just (Route.CreateSnipbitCodeFramePage _) ->
            "create-snipbit"

        Just Route.CreateBigbitNamePage ->
            "create-bigbit"

        Just Route.CreateBigbitDescriptionPage ->
            "create-bigbit"

        Just Route.CreateBigbitTagsPage ->
            "create-bigbit"

        Just (Route.CreateBigbitCodeFramePage _ _) ->
            "create-bigbit"

        Just (Route.CreateStoryNamePage maybeEditingStory) ->
            case maybeEditingStory of
                Nothing ->
                    "create-story"

                Just _ ->
                    "edit-story"

        Just (Route.CreateStoryDescriptionPage maybeEditingStory) ->
            case maybeEditingStory of
                Nothing ->
                    "create-story"

                Just _ ->
                    "edit-story"

        Just (Route.CreateStoryTagsPage maybeEditingStory) ->
            case maybeEditingStory of
                Nothing ->
                    "create-story"

                Just _ ->
                    "edit-story"

        Just (Route.DevelopStoryPage _) ->
            "develop-story"

        Just Route.ProfilePage ->
            "profile"

        Just (Route.LoginPage maybeRedirectLink) ->
            case maybeRedirectLink of
                Nothing ->
                    "login-direct"

                Just _ ->
                    "login-redirect"

        Just (Route.RegisterPage maybeRedirectLink) ->
            case maybeRedirectLink of
                Nothing ->
                    "register-direct"

                Just _ ->
                    "register-redirect"

        Just Route.NotificationsPage ->
            "notifications"
