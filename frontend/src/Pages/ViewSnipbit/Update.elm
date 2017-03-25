module Pages.ViewSnipbit.Update exposing (..)

import Api
import Array
import DefaultServices.Util as Util exposing (maybeMapWithDefault)
import Elements.Editor as Editor
import Models.Completed as Completed
import Models.Range as Range
import Models.Route as Route
import Models.Snipbit as Snipbit
import Models.TidbitPointer as TidbitPointer
import Models.User as User
import Models.ViewerRelevantHC as ViewerRelevantHC
import Pages.Model exposing (Shared)
import Pages.ViewSnipbit.Messages exposing (Msg(..))
import Pages.ViewSnipbit.Model exposing (..)
import Ports


{-| `ViewSnipbit` update.
-}
update : Msg -> Model -> Shared -> ( Model, Shared, Cmd Msg )
update msg model shared =
    let
        doNothing =
            ( model, shared, Cmd.none )

        justSetModel newModel =
            ( newModel, shared, Cmd.none )

        justSetShared newShared =
            ( model, newShared, Cmd.none )

        justProduceCmd newCmd =
            ( model, shared, newCmd )

        justUpdateModel modelUpdater =
            ( modelUpdater model, shared, Cmd.none )

        withCmd : Cmd Msg -> ( Model, Shared, Cmd Msg ) -> ( Model, Shared, Cmd Msg )
        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )

        -- For when you need to do multiple things all which change model/shared/cmd.
        handleAll : List (( Model, Shared ) -> ( Model, Shared, Cmd Msg )) -> ( Model, Shared, Cmd Msg )
        handleAll =
            let
                go ( lastModel, lastShared, lastCmd ) listOfThingsToHandle =
                    case listOfThingsToHandle of
                        [] ->
                            ( lastModel, lastShared, lastCmd )

                        handleCurrent :: xs ->
                            go (withCmd lastCmd (handleCurrent ( lastModel, lastShared ))) xs
            in
                go ( model, shared, Cmd.none )
    in
        case msg of
            NoOp ->
                doNothing

            GoTo route ->
                justProduceCmd <| Route.navigateTo route

            OnRouteHit route ->
                let
                    {- Get's data for viewing snipbit as required:
                          - May need to fetch tidbit itself
                          - May need to fetch story
                          - May need to fetch if the tidbit is completed by the user.

                       TODO ISSUE#99 Update to check cache if it is expired.
                    -}
                    fetchOrRenderViewSnipbitData mongoID =
                        let
                            currentTidbitPointer =
                                TidbitPointer.TidbitPointer
                                    TidbitPointer.Snipbit
                                    mongoID

                            -- Handle getting snipbit if needed.
                            handleGetSnipbit : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetSnipbit ( model, shared ) =
                                let
                                    getSnipbit mongoID =
                                        ( setViewingSnipbit Nothing model
                                        , shared
                                        , Api.getSnipbit
                                            mongoID
                                            OnGetSnipbitFailure
                                            OnGetSnipbitSuccess
                                        )
                                in
                                    case model.viewingSnipbit of
                                        Nothing ->
                                            getSnipbit mongoID

                                        Just snipbit ->
                                            if snipbit.id == mongoID then
                                                ( setViewingSnipbitRelevantHC Nothing model
                                                , shared
                                                , createViewSnipbitCodeEditor snipbit shared
                                                )
                                            else
                                                getSnipbit mongoID

                            -- Handle getting snipbit is-completed if needed.
                            handleGetSnipbitIsCompleted : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetSnipbitIsCompleted ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    getSnipbitIsCompleted userID =
                                        ( setViewingSnipbitIsCompleted Nothing model
                                        , shared
                                        , Api.postCheckCompletedWrapper
                                            (Completed.Completed currentTidbitPointer userID)
                                            ViewSnipbitGetCompletedFailure
                                            ViewSnipbitGetCompletedSuccess
                                        )
                                in
                                    case ( shared.user, model.viewingSnipbitIsCompleted ) of
                                        ( Just user, Nothing ) ->
                                            getSnipbitIsCompleted user.id

                                        ( Just user, Just currentCompleted ) ->
                                            if currentCompleted.tidbitPointer == currentTidbitPointer then
                                                doNothing
                                            else
                                                getSnipbitIsCompleted user.id

                                        _ ->
                                            doNothing

                            -- Handle getting story if viewing snipbit from story.
                            handleGetStoryForSnipbit : ( Model, Shared ) -> ( Model, Shared, Cmd Msg )
                            handleGetStoryForSnipbit ( model, shared ) =
                                let
                                    doNothing =
                                        ( model, shared, Cmd.none )

                                    maybeViewingStoryID =
                                        Maybe.map .id shared.viewingStory

                                    getStory storyID =
                                        Api.getExpandedStoryWithCompleted
                                            storyID
                                            ViewSnipbitGetExpandedStoryFailure
                                            ViewSnipbitGetExpandedStorySuccess
                                in
                                    case Route.getFromStoryQueryParamOnViewSnipbitRoute shared.route of
                                        Just storyID ->
                                            if (Just storyID) == maybeViewingStoryID then
                                                doNothing
                                            else
                                                ( model
                                                , { shared
                                                    | viewingStory = Nothing
                                                  }
                                                , getStory storyID
                                                )

                                        _ ->
                                            ( model
                                            , { shared
                                                | viewingStory = Nothing
                                              }
                                            , Cmd.none
                                            )
                        in
                            handleAll
                                [ handleGetSnipbit
                                , handleGetSnipbitIsCompleted
                                , handleGetStoryForSnipbit
                                ]
                in
                    case route of
                        Route.ViewSnipbitIntroductionPage _ mongoID ->
                            fetchOrRenderViewSnipbitData mongoID

                        Route.ViewSnipbitFramePage _ mongoID _ ->
                            fetchOrRenderViewSnipbitData mongoID

                        Route.ViewSnipbitConclusionPage _ mongoID ->
                            fetchOrRenderViewSnipbitData mongoID
                                |> withCmd
                                    (case ( shared.user, model.viewingSnipbitIsCompleted ) of
                                        ( Just user, Just isCompleted ) ->
                                            let
                                                completed =
                                                    Completed.completedFromIsCompleted isCompleted user.id
                                            in
                                                if isCompleted.complete == False then
                                                    Api.postAddCompletedWrapper completed ViewSnipbitMarkAsCompleteFailure ViewSnipbitMarkAsCompleteSuccess
                                                else
                                                    Cmd.none

                                        _ ->
                                            Cmd.none
                                    )

                        _ ->
                            doNothing

            OnGetSnipbitFailure apiError ->
                -- TODO handle error.
                doNothing

            OnGetSnipbitSuccess snipbit ->
                ( Util.multipleUpdates
                    [ setViewingSnipbit <| Just snipbit
                    , setViewingSnipbitRelevantHC Nothing
                    ]
                    model
                , shared
                , createViewSnipbitCodeEditor snipbit shared
                )

            ViewSnipbitRangeSelected selectedRange ->
                case model.viewingSnipbit of
                    Nothing ->
                        doNothing

                    Just aSnipbit ->
                        if Range.isEmptyRange selectedRange then
                            justUpdateModel <|
                                setViewingSnipbitRelevantHC Nothing
                        else
                            aSnipbit.highlightedComments
                                |> Array.indexedMap (,)
                                |> Array.filter (Tuple.second >> .range >> (Range.overlappingRanges selectedRange))
                                |> (\relevantHC ->
                                        justUpdateModel <|
                                            setViewingSnipbitRelevantHC <|
                                                Just
                                                    { currentHC = Nothing
                                                    , relevantHC = relevantHC
                                                    }
                                   )

            ViewSnipbitBrowseRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC
                            (\currentRelevantHC ->
                                { currentRelevantHC
                                    | currentHC = Just 0
                                }
                            )
                            model
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor
                        newModel.viewingSnipbit
                        newModel.viewingSnipbitRelevantHC
                        shared.user
                    )

            ViewSnipbitCancelBrowseRelevantHC ->
                ( setViewingSnipbitRelevantHC Nothing model
                , shared
                  -- Trigger route hook again, `modify` because we don't want to
                  -- have the same page twice in the history.
                , Route.modifyTo shared.route
                )

            ViewSnipbitNextRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC
                            ViewerRelevantHC.goToNextFrame
                            model
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor
                        newModel.viewingSnipbit
                        newModel.viewingSnipbitRelevantHC
                        shared.user
                    )

            ViewSnipbitPreviousRelevantHC ->
                let
                    newModel =
                        updateViewingSnipbitRelevantHC
                            ViewerRelevantHC.goToPreviousFrame
                            model
                in
                    ( newModel
                    , shared
                    , createViewSnipbitHCCodeEditor
                        newModel.viewingSnipbit
                        newModel.viewingSnipbitRelevantHC
                        shared.user
                    )

            ViewSnipbitJumpToFrame route ->
                ( setViewingSnipbitRelevantHC Nothing model
                , shared
                , Route.navigateTo route
                )

            ViewSnipbitGetCompletedSuccess isCompleted ->
                justUpdateModel <|
                    setViewingSnipbitIsCompleted <|
                        Just isCompleted

            ViewSnipbitGetCompletedFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsComplete completed ->
                justProduceCmd <|
                    Api.postAddCompletedWrapper
                        completed
                        ViewSnipbitMarkAsCompleteFailure
                        ViewSnipbitMarkAsCompleteSuccess

            ViewSnipbitMarkAsCompleteSuccess isCompleted ->
                justUpdateModel <|
                    setViewingSnipbitIsCompleted <|
                        Just isCompleted

            ViewSnipbitMarkAsCompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitMarkAsIncomplete completed ->
                justProduceCmd <|
                    Api.postRemoveCompletedWrapper
                        completed
                        ViewSnipbitMarkAsIncompleteFailure
                        ViewSnipbitMarkAsIncompleteSuccess

            ViewSnipbitMarkAsIncompleteSuccess isCompleted ->
                justUpdateModel <|
                    setViewingSnipbitIsCompleted <|
                        Just isCompleted

            ViewSnipbitMarkAsIncompleteFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitGetExpandedStoryFailure apiError ->
                -- TODO handle error.
                doNothing

            ViewSnipbitGetExpandedStorySuccess expandedStory ->
                justSetShared
                    { shared
                        | viewingStory = Just expandedStory
                    }


{-| Creates the editor for the snipbit.

Will handle redirects if bad path and highlighting code.
-}
createViewSnipbitCodeEditor : Snipbit.Snipbit -> Shared -> Cmd msg
createViewSnipbitCodeEditor snipbit { route, user } =
    let
        editorWithRange range =
            Ports.createCodeEditor
                { id = "view-snipbit-code-editor"
                , fileID = ""
                , lang = Editor.aceLanguageLocation snipbit.language
                , theme = User.getTheme user
                , value = snipbit.code
                , range = range
                , readOnly = True
                , selectAllowed = True
                }
    in
        Cmd.batch
            [ case route of
                Route.ViewSnipbitIntroductionPage _ _ ->
                    editorWithRange Nothing

                Route.ViewSnipbitConclusionPage _ _ ->
                    editorWithRange Nothing

                Route.ViewSnipbitFramePage fromStoryID mongoID frameNumber ->
                    if frameNumber > Array.length snipbit.highlightedComments then
                        Route.modifyTo <|
                            Route.ViewSnipbitConclusionPage fromStoryID mongoID
                    else if frameNumber < 1 then
                        Route.modifyTo <|
                            Route.ViewSnipbitIntroductionPage fromStoryID mongoID
                    else
                        (Array.get
                            (frameNumber - 1)
                            snipbit.highlightedComments
                        )
                            |> Maybe.map .range
                            |> editorWithRange

                _ ->
                    Cmd.none
            , Ports.smoothScrollToBottom
            ]


{-| Creates the code editor for the snipbit when browsing the relevant HC.

This will only create the editor if the state of the model (the `Maybe`s) makes
it appropriate to render the editor.
-}
createViewSnipbitHCCodeEditor : Maybe Snipbit.Snipbit -> Maybe ViewingSnipbitRelevantHC -> Maybe User.User -> Cmd msg
createViewSnipbitHCCodeEditor maybeSnipbit maybeRHC user =
    case ( maybeSnipbit, maybeRHC ) of
        ( Just snipbit, Just { currentHC, relevantHC } ) ->
            let
                editorWithRange range =
                    Ports.createCodeEditor
                        { id = "view-snipbit-code-editor"
                        , fileID = ""
                        , lang = Editor.aceLanguageLocation snipbit.language
                        , theme = User.getTheme user
                        , value = snipbit.code
                        , range = Just range
                        , readOnly = True
                        , selectAllowed = False
                        }
            in
                case currentHC of
                    Nothing ->
                        Cmd.none

                    Just index ->
                        Array.get index relevantHC
                            |> maybeMapWithDefault
                                (editorWithRange << .range << Tuple.second)
                                Cmd.none

        _ ->
            Cmd.none
