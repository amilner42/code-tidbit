module DefaultServices.BasePageUtil exposing (..)

import Api
import Models.ApiError as ApiError
import Models.RequestTracker as RT
import Pages.Model as BaseModel


{-| All the utilities for manipulating `Model` -> `(Model, Cmd Msg)`.

NOTE: It's a type wrapper around an alias (instead of just a type alias) to allow for recursion:

  - <https://github.com/elm-lang/elm-compiler/blob/0.18.0/hints/recursive-alias.md>

-}
type BasePageUtil msg
    = BasePageUtil
        { justSetModel : BaseModel.Model -> ( BaseModel.Model, Cmd.Cmd msg )
        , justUpdateModel : (BaseModel.Model -> BaseModel.Model) -> ( BaseModel.Model, Cmd.Cmd msg )
        , justSetShared : BaseModel.Shared -> ( BaseModel.Model, Cmd.Cmd msg )
        , justUpdateShared : (BaseModel.Shared -> BaseModel.Shared) -> ( BaseModel.Model, Cmd.Cmd msg )
        , justProduceCmd : Cmd.Cmd msg -> ( BaseModel.Model, Cmd.Cmd msg )
        , doNothing : ( BaseModel.Model, Cmd.Cmd msg )
        , withCmd : Cmd.Cmd msg -> ( BaseModel.Model, Cmd.Cmd msg ) -> ( BaseModel.Model, Cmd.Cmd msg )
        , handleAll :
            List (BasePageUtil msg -> BaseModel.Model -> ( BaseModel.Model, Cmd msg )) -> ( BaseModel.Model, Cmd msg )
        , justSetModalError : ApiError.ApiError -> ( BaseModel.Model, Cmd.Cmd msg )
        , makeSingletonRequest : RT.TrackedRequest -> ( BaseModel.Model, Cmd.Cmd msg ) -> ( BaseModel.Model, Cmd.Cmd msg )
        , andFinishRequest : RT.TrackedRequest -> ( BaseModel.Model, Cmd.Cmd msg ) -> ( BaseModel.Model, Cmd.Cmd msg )
        }


{-| Creates the `BasePageUtil` given the `model`.

We put `BaseModel.Model` as a concrete type to allow for more useful helper functions.

-}
basePageUtil : BaseModel.Model -> BasePageUtil msg
basePageUtil model =
    let
        withCmd withCmd ( newModel, newCmd ) =
            ( newModel, Cmd.batch [ newCmd, withCmd ] )

        handleAll =
            let
                go ( lastModel, lastCmd ) listOfThingsToHandle =
                    case listOfThingsToHandle of
                        [] ->
                            ( lastModel, lastCmd )

                        handleCurrent :: xs ->
                            go (withCmd lastCmd <| handleCurrent (basePageUtil lastModel) lastModel) xs
            in
            go ( model, Cmd.none )
    in
    BasePageUtil
        { justSetModel = \newModel -> ( newModel, Cmd.none )
        , justUpdateModel = \updateModel -> ( updateModel model, Cmd.none )
        , justSetShared = \newShared -> ( { model | shared = newShared }, Cmd.none )
        , justUpdateShared = \sharedUpdater -> ( BaseModel.updateShared model sharedUpdater, Cmd.none )
        , justProduceCmd = \newCmd -> ( model, newCmd )
        , doNothing = ( model, Cmd.none )
        , withCmd = withCmd
        , handleAll = handleAll
        , justSetModalError =
            \apiError ->
                ( BaseModel.updateShared model (\shared -> { shared | apiModalError = Just apiError })
                , Cmd.none
                )
        , makeSingletonRequest =
            \trackedRequest ( newModel, newCmd ) ->
                if RT.isMakingRequest model.shared.apiRequestTracker trackedRequest then
                    ( model, Cmd.none )
                else
                    ( BaseModel.updateShared
                        newModel
                        (\newShared ->
                            { newShared
                                | apiRequestTracker = RT.startRequest trackedRequest newShared.apiRequestTracker
                            }
                        )
                    , newCmd
                    )
        , andFinishRequest =
            \trackedRequest ( newModel, newCmd ) ->
                ( BaseModel.updateShared
                    newModel
                    (\newShared ->
                        { newShared | apiRequestTracker = RT.finishRequest trackedRequest newShared.apiRequestTracker }
                    )
                , newCmd
                )
        }
