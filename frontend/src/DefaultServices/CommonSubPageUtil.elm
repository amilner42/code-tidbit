module DefaultServices.CommonSubPageUtil exposing (..)

import Api
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Pages.Model exposing (Shared)


{-| All the common utilities for manipulating `(Model, Shared)` -> `(Model, Shared, Cmd Msg)`.

NOTE: It's a type wrapper around an alias (instead of just a type alias) to allow for recursion:

  - <https://github.com/elm-lang/elm-compiler/blob/0.18.0/hints/recursive-alias.md>

-}
type CommonSubPageUtil model shared subMsg baseMsg
    = Common
        { subMsg : subMsg -> baseMsg
        , justSetModel : model -> ( model, shared, Cmd.Cmd baseMsg )
        , justUpdateModel : (model -> model) -> ( model, shared, Cmd.Cmd baseMsg )
        , justSetShared : shared -> ( model, shared, Cmd.Cmd baseMsg )
        , justUpdateShared : (shared -> shared) -> ( model, shared, Cmd.Cmd baseMsg )
        , justProduceCmd : Cmd.Cmd baseMsg -> ( model, shared, Cmd.Cmd baseMsg )
        , doNothing : ( model, shared, Cmd.Cmd baseMsg )
        , withCmd : Cmd.Cmd baseMsg -> ( model, shared, Cmd.Cmd baseMsg ) -> ( model, shared, Cmd.Cmd baseMsg )
        , handleAll :
            List (CommonSubPageUtil model shared subMsg baseMsg -> ( model, shared ) -> ( model, shared, Cmd baseMsg ))
            -> ( model, shared, Cmd baseMsg )
        , justSetModalError : ApiError.ApiError -> ( model, shared, Cmd.Cmd baseMsg )
        , makeSingletonRequest :
            RT.TrackedRequest -> ( model, shared, Cmd.Cmd baseMsg ) -> ( model, shared, Cmd.Cmd baseMsg )
        , andFinishRequest : RT.TrackedRequest -> ( model, shared, Cmd.Cmd baseMsg ) -> ( model, shared, Cmd.Cmd baseMsg )
        }


{-| Creates the `CommonSubPageUtil` given the `model` and `shared`.

As you can see, this declares `Shared` instead of leaving it as a type parameter, this allows us to define a few extra
helpful functions for sub-pages.

-}
commonSubPageUtil : (subMsg -> baseMsg) -> model -> Shared -> CommonSubPageUtil model Shared subMsg baseMsg
commonSubPageUtil subMsg model shared =
    let
        withCmd withCmd ( newModel, newShared, newCmd ) =
            ( newModel, newShared, Cmd.batch [ newCmd, withCmd ] )

        handleAll =
            let
                go ( lastModel, lastShared, lastCmd ) listOfThingsToHandle =
                    case listOfThingsToHandle of
                        [] ->
                            ( lastModel, lastShared, lastCmd )

                        handleCurrent :: xs ->
                            go
                                (withCmd lastCmd <|
                                    handleCurrent (commonSubPageUtil subMsg lastModel lastShared) ( lastModel, lastShared )
                                )
                                xs
            in
            go ( model, shared, Cmd.none )
    in
    Common
        { subMsg = subMsg
        , justSetModel = \newModel -> ( newModel, shared, Cmd.none )
        , justUpdateModel = \modelUpdater -> ( modelUpdater model, shared, Cmd.none )
        , justSetShared = \newShared -> ( model, newShared, Cmd.none )
        , justUpdateShared = \sharedUpdater -> ( model, sharedUpdater shared, Cmd.none )
        , justProduceCmd = \newCmd -> ( model, shared, newCmd )
        , doNothing = ( model, shared, Cmd.none )
        , withCmd = withCmd
        , handleAll = handleAll
        , justSetModalError = \apiError -> ( model, { shared | apiModalError = Just apiError }, Cmd.none )
        , makeSingletonRequest =
            \trackedRequest ( newModel, newShared, newCmd ) ->
                if RT.isMakingRequest shared.apiRequestTracker trackedRequest then
                    ( model, shared, Cmd.none )
                else
                    ( newModel
                    , { newShared | apiRequestTracker = RT.startRequest trackedRequest newShared.apiRequestTracker }
                    , newCmd
                    )
        , andFinishRequest =
            \trackedRequest ( newModel, newShared, newCmd ) ->
                ( newModel
                , { newShared | apiRequestTracker = RT.finishRequest trackedRequest newShared.apiRequestTracker }
                , newCmd
                )
        }
