module Components.Update exposing (update, updateCacheIf)

import Array
import Api
import Components.Home.Update as HomeUpdate
import Components.Home.Messages as HomeMessages
import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model)
import Components.Welcome.Update as WelcomeUpdate
import DefaultServices.LocalStorage as LocalStorage
import DefaultServices.Util as Util
import Elements.Editor as Editor
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

                        _ ->
                            doNothing

                CodeEditorSelectionUpdate { id, range } ->
                    case id of
                        "create-snipbit-code-editor" ->
                            (updateCacheIf
                                (HomeMessage <|
                                    HomeMessages.SnipbitNewRangeSelected
                                        range
                                )
                                model
                                shouldCache
                            )

                        _ ->
                            doNothing
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

                aceLang =
                    case model.homeComponent.snipbitCreateData.language of
                        Nothing ->
                            ""

                        Just aLanguage ->
                            Editor.aceLanguageLocation aLanguage

                -- TODO Get theme from `shared.user`.
                aceTheme =
                    ""

                aceValue =
                    model.homeComponent.snipbitCreateData.code

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
                                                [ Route.navigateTo newModel.shared.route
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
                                                [ Route.navigateTo newModel.shared.route
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

                newCmdBatchedWithCreateSnipbitEditor aceRange =
                    Cmd.batch
                        [ newCmd
                        , Ports.createCodeEditor
                            { id = "create-snipbit-code-editor"
                            , lang = aceLang
                            , theme = aceTheme
                            , value = aceValue
                            , range = aceRange
                            , readOnly = False
                            }
                        ]

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
                        ( newModel
                        , newCmdBatchedWithCreateSnipbitEditor Nothing
                        )

                    -- Init the editor.
                    Route.HomeComponentCreateSnipbitCodeConclusion ->
                        ( newModel
                        , newCmdBatchedWithCreateSnipbitEditor Nothing
                        )

                    Route.HomeComponentCreateSnipbitCodeFrame frameNumber ->
                        let
                            -- 0 based indexing.
                            frameIndex =
                                frameNumber - 1

                            frameIndexTooHigh =
                                frameIndex >= (Array.length model.homeComponent.snipbitCreateData.highlightedComments)

                            frameIndexTooLow =
                                frameIndex < 0
                        in
                            if frameIndexTooHigh || frameIndexTooLow then
                                ( newModel
                                , Cmd.batch
                                    [ newCmd
                                    , Route.navigateTo
                                        Route.HomeComponentCreateSnipbitCodeIntroduction
                                    ]
                                )
                            else
                                ( newModel
                                , newCmdBatchedWithCreateSnipbitEditor <|
                                    Maybe.andThen
                                        .range
                                        (Array.get
                                            frameIndex
                                            model.homeComponent.snipbitCreateData.highlightedComments
                                        )
                                )

                    Route.HomeComponentViewSnipbitIntroduction _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewSnipbitConclusion _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentViewSnipbitFrame _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeIntroduction _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeFrame _ _ ->
                        triggerRouteHookOnHomeComponent

                    Route.HomeComponentCreateBigbitCodeConclusion _ ->
                        triggerRouteHookOnHomeComponent

                    _ ->
                        ( newModel, newCmd )
